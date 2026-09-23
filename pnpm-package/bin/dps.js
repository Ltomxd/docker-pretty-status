#!/usr/bin/env node
"use strict";

const { spawnSync } = require("node:child_process");
const path = require("node:path");

const script = path.join(__dirname, "..", "dps.sh");
const result = spawnSync("bash", [script, ...process.argv.slice(2)], {
  stdio: "inherit",
});

if (result.error) {
  if (result.error.code === "ENOENT") {
    console.error("dps: 'bash' not found in PATH. Install bash 4+ to use dps.");
  } else {
    console.error(`dps: failed to run: ${result.error.message}`);
  }
  process.exit(1);
}

process.exit(result.status ?? 1);
