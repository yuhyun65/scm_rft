import { useEffect, useState } from "react";
import { describePortalScope } from "@scm-rft/ui";
import { readContractCatalog } from "@scm-rft/api-client";
import { AuthMemberPanel } from "./features/auth-member-panel";

const TOKEN_STORAGE_KEY = "scm-rft.access-token";

export function formatPortalTitle(scope: string) {
  return `SCM Web Portal (${scope})`;
}

function readStoredToken() {
  return window.localStorage.getItem(TOKEN_STORAGE_KEY) ?? "";
}

export default function App() {
  const catalog = readContractCatalog();
  const [accessToken, setAccessToken] = useState(() => readStoredToken());
  const title = formatPortalTitle(describePortalScope("scm-rft"));
  const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? "";

  useEffect(() => {
    if (accessToken) {
      window.localStorage.setItem(TOKEN_STORAGE_KEY, accessToken);
      return;
    }
    window.localStorage.removeItem(TOKEN_STORAGE_KEY);
  }, [accessToken]);

  return (
    <main className="shell">
      <header className="hero">
        <p className="eyebrow">Frontend Modernization</p>
        <h1>{title}</h1>
        <p className="heroText">
          The first user-facing slice targets Auth and Member flows so SCM-246 can validate the
          token contract before Order-Lot UI starts.
        </p>
        <div className="heroMeta">
          <span>Contracts: {catalog.contracts.length}</span>
          <span>Gateway base: {apiBaseUrl || "(same origin)"}</span>
        </div>
      </header>

      <AuthMemberPanel
        apiBaseUrl={apiBaseUrl}
        accessToken={accessToken}
        onAccessTokenChange={setAccessToken}
      />
    </main>
  );
}
