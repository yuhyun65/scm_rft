import fs from "node:fs";
import path from "node:path";

const appRoot = process.cwd();
const requiredFiles = [
  "index.html",
  path.join("src", "main.tsx"),
  path.join("src", "App.tsx")
];

const missing = requiredFiles.filter((file) => !fs.existsSync(path.join(appRoot, file)));
if (missing.length > 0) {
  console.error(`[FAIL] frontend-e2e-smoke: missing file(s): ${missing.join(", ")}`);
  process.exit(1);
}

console.log("[OK] frontend-e2e-smoke: baseline files are present.");
