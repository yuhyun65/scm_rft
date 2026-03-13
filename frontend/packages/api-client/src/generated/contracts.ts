export type ContractCatalog = {
  generatedAt: string;
  contracts: Array<{ name: string; path: string }>;
};

export const contractCatalog: ContractCatalog = {
  generatedAt: "2026-03-13T01:15:54.969Z",
  contracts: [
    { name: "auth.openapi.yaml", path: "shared/contracts/auth.openapi.yaml" },
    { name: "board.openapi.yaml", path: "shared/contracts/board.openapi.yaml" },
    { name: "file.openapi.yaml", path: "shared/contracts/file.openapi.yaml" },
    { name: "inventory.openapi.yaml", path: "shared/contracts/inventory.openapi.yaml" },
    { name: "member.openapi.yaml", path: "shared/contracts/member.openapi.yaml" },
    { name: "order-lot.openapi.yaml", path: "shared/contracts/order-lot.openapi.yaml" },
    { name: "quality-doc.openapi.yaml", path: "shared/contracts/quality-doc.openapi.yaml" },
    { name: "report.openapi.yaml", path: "shared/contracts/report.openapi.yaml" }
  ]
};
