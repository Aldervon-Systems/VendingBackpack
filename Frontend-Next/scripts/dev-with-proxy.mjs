#!/usr/bin/env node

import http from "node:http";
import net from "node:net";
import { spawn } from "node:child_process";
import path from "node:path";

const proxyPort = Number.parseInt(process.env.PORT ?? "3002", 10);
const nextPort = Number.parseInt(process.env.NEXT_DEV_PORT ?? String(proxyPort + 1), 10);
const backendHost = process.env.NEXT_DEV_BACKEND_HOST ?? "127.0.0.1";
const backendPort = Number.parseInt(process.env.NEXT_DEV_BACKEND_PORT ?? "9090", 10);
const nextBin = path.join(process.cwd(), "node_modules", "next", "dist", "bin", "next");

const nextDev = spawn(
  process.execPath,
  [nextBin, "dev", "-p", String(nextPort)],
  {
    env: {
      ...process.env,
      PORT: String(nextPort),
    },
    stdio: "inherit",
  },
);

nextDev.on("exit", (code, signal) => {
  if (signal) {
    process.exitCode = 1;
    return;
  }

  process.exitCode = code ?? 0;
});

function forwardHttpRequest(targetHost, targetPort, req, res, targetPath = req.url ?? "/") {
  const proxy = http.request(
    {
      host: targetHost,
      port: targetPort,
      method: req.method,
      path: targetPath,
      headers: {
        ...req.headers,
        host: `${targetHost}:${targetPort}`,
        "x-forwarded-host": req.headers.host ?? `localhost:${proxyPort}`,
        "x-forwarded-proto": "http",
        "x-forwarded-for": req.socket.remoteAddress ?? "",
      },
    },
    (targetRes) => {
      res.writeHead(targetRes.statusCode ?? 502, targetRes.headers);
      targetRes.pipe(res);
    },
  );

  proxy.on("error", (error) => {
    if (!res.headersSent) {
      res.statusCode = 502;
      res.setHeader("Content-Type", "text/plain; charset=utf-8");
    }
    res.end(`Proxy error: ${error.message}`);
  });

  req.pipe(proxy);
}

const proxyServer = http.createServer((req, res) => {
  const requestUrl = new URL(req.url ?? "/", `http://${req.headers.host ?? `localhost:${proxyPort}`}`);
  const pathname = requestUrl.pathname;

  if (pathname === "/api" || pathname.startsWith("/api/")) {
    forwardHttpRequest(backendHost, backendPort, req, res, pathname + requestUrl.search);
    return;
  }

  if (pathname === "/health") {
    forwardHttpRequest(backendHost, backendPort, req, res, "/health");
    return;
  }

  forwardHttpRequest("127.0.0.1", nextPort, req, res, req.url ?? "/");
});

proxyServer.on("upgrade", (req, socket, head) => {
  const requestUrl = new URL(req.url ?? "/", `http://${req.headers.host ?? `localhost:${proxyPort}`}`);
  const pathname = requestUrl.pathname;

  if (pathname === "/api" || pathname.startsWith("/api/") || pathname === "/health") {
    socket.destroy();
    return;
  }

  const upstream = net.connect(nextPort, "127.0.0.1", () => {
    const headers = Object.entries(req.headers)
      .filter(([key]) => {
        const normalized = key.toLowerCase();
        return normalized !== "proxy-connection" && normalized !== "host";
      })
      .map(([key, value]) => `${key}: ${value}`)
      .join("\r\n");

    upstream.write(
      `${req.method ?? "GET"} ${req.url ?? "/"} HTTP/1.1\r\n` +
        `Host: 127.0.0.1:${nextPort}\r\n` +
        `${headers}\r\n\r\n`,
    );

    if (head.length) {
      upstream.write(head);
    }

    socket.pipe(upstream).pipe(socket);
  });

  upstream.on("error", () => {
    socket.destroy();
  });
});

proxyServer.listen(proxyPort, "0.0.0.0", () => {
  console.log(`Next dev proxy listening on http://localhost:${proxyPort}`);
});

function shutdown(signal) {
  proxyServer.close();
  nextDev.kill(signal);
}

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
