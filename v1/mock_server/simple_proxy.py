#!/usr/bin/env python3
"""
Simple static file server + proxy for demo mode.

Serves files from ../build/web on port 3000 and proxies requests
starting with /__demo_api/ to http://localhost:8000.

Run: python3 simple_proxy.py
"""
import http.server
import socketserver
import urllib.request
import urllib.error
import sys
import threading
from http import HTTPStatus

PORT = 3000
API_TARGET = 'http://127.0.0.1:8000'
STATIC_DIR = '../build/web'


class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=STATIC_DIR, **kwargs)

    def do_PROXY(self):
        # Map incoming path to API target
        # If frontend calls bare endpoints (e.g. /inventory) rewrite to /__demo_api/<path>
        path = self.path
        if path.startswith('/__demo_api/'):
            target_url = API_TARGET + path
        else:
            # rewrite known demo paths to the Flask demo prefix
            known = (
                '/inventory', '/status', '/daily_stats', '/employee_routes', '/employee', '/machines', '/routes',
                '/auth', '/login', '/locations', '/localdata/locations', '/local_data/locations',
                '/data/locations.json', '/assets/locations.json'
            )
            if any(path.startswith(k) for k in known):
                # ensure single slash between
                target_url = API_TARGET + '/__demo_api' + (path if path.startswith('/') else '/' + path)
            else:
                target_url = API_TARGET + path

        # Log mapping for easier debugging
        try:
            with open('proxy.log', 'a') as lf:
                lf.write(f"PROXY: {self.command} {path} -> {target_url}\n")
        except Exception:
            pass
        try:
            req_headers = {k: v for k, v in self.headers.items()}
            data = None
            if 'Content-Length' in self.headers:
                length = int(self.headers['Content-Length'])
                data = self.rfile.read(length)

            req = urllib.request.Request(target_url, data=data, headers=req_headers, method=self.command)
            with urllib.request.urlopen(req, timeout=10) as resp:
                self.send_response(resp.getcode())
                for k, v in resp.getheaders():
                    # Avoid sending transfer-encoding hop-by-hop
                    if k.lower() in ('transfer-encoding', 'connection', 'keep-alive'):
                        continue
                    self.send_header(k, v)
                self.end_headers()
                body = resp.read()
                if body:
                    self.wfile.write(body)
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.end_headers()
            try:
                self.wfile.write(e.read())
            except Exception:
                pass
        except Exception as e:
            self.send_response(HTTPStatus.INTERNAL_SERVER_ERROR)
            self.end_headers()
            self.wfile.write(str(e).encode('utf-8'))

    def do_GET(self):
        # Proxy demo API endpoints whether they are prefixed with /__demo_api/ or referenced directly
        if self.path.startswith('/__demo_api/') or self.path.startswith('/inventory') or self.path.startswith('/status') or self.path.startswith('/daily_stats') or self.path.startswith('/employee_routes') or self.path.startswith('/employee') or self.path.startswith('/auth') or self.path.startswith('/login'):
            return self.do_PROXY()
        return super().do_GET()

    def do_POST(self):
        if self.path.startswith('/__demo_api/') or self.path.startswith('/inventory') or self.path.startswith('/auth') or self.path.startswith('/login'):
            return self.do_PROXY()
        return super().do_POST()


def run():
    with socketserver.ThreadingTCPServer(('', PORT), ProxyHandler) as httpd:
        sa = httpd.socket.getsockname()
        print(f"Serving HTTP on {sa[0]} port {sa[1]} (http://localhost:{PORT}) ...")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print('\nShutting down')
            httpd.server_close()


if __name__ == '__main__':
    run()
