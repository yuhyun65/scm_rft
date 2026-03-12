import fs from "node:fs";
import path from "node:path";

const packageRoot = process.cwd();
const repoRoot = path.resolve(packageRoot, "..", "..", "..");
const contractsDir = path.join(repoRoot, "shared", "contracts");
const outputFile = path.join(packageRoot, "src", "generated", "contracts.ts");

if (!fs.existsSync(contractsDir)) {
  console.error(`[FAIL] contract:generate: contracts dir not found: ${contractsDir}`);
  process.exit(1);
}

const files = fs
  .readdirSync(contractsDir, { withFileTypes: true })
  .filter((entry) => entry.isFile() && /\.openapi\.ya?ml$/i.test(entry.name))
  .map((entry) => entry.name)
  .sort();

const generatedAt = new Date().toISOString();
const body = `export type ContractCatalog = {
  generatedAt: string;
  contracts: Array<{ name: string; path: string }>;
};

export const contractCatalog: ContractCatalog = {
  generatedAt: ${JSON.stringify(generatedAt)},
  contracts: [
${files
  .map((name) => `    { name: ${JSON.stringify(name)}, path: ${JSON.stringify(`shared/contracts/${name}`)} }`)
  .join(",\n")}
  ]
};
`;

fs.writeFileSync(outputFile, body, "utf8");
console.log(`[OK] contract:generate: ${files.length} contract(s) -> ${outputFile}`);
