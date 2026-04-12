import { spawn } from "node:child_process";

const child = spawn("./node_modules/.bin/next", ["build"], {
  stdio: "inherit",
  env: process.env,
  shell: false,
});

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }

  process.exit(code ?? 1);
});
