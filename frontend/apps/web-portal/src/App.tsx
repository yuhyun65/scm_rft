import { describePortalScope } from "@scm-rft/ui";
import { readContractCatalog } from "@scm-rft/api-client";

export function formatPortalTitle(scope: string): string {
  return `SCM Web Portal (${scope})`;
}

export default function App() {
  const catalog = readContractCatalog();
  const title = formatPortalTitle(describePortalScope("scm-rft"));

  return (
    <main className="shell">
      <h1>{title}</h1>
      <p>Frontend modernization baseline is ready.</p>
      <ul>
        <li>Contracts discovered: {catalog.contracts.length}</li>
        <li>Traceable source: shared/contracts/*.openapi.yaml</li>
        <li>Next step: implement Auth/Member MVP UI</li>
      </ul>
    </main>
  );
}
