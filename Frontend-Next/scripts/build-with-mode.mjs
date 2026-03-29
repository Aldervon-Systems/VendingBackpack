import { spawn } from "node:child_process";

const args = process.argv.slice(2);
if (args.includes("-seed")) {
  process.env.NEXT_PUBLIC_AUTH_MODE = "seed";
}

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
