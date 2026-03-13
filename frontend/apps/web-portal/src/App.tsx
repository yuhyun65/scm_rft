import { useEffect, useState } from "react";
import { describePortalScope } from "@scm-rft/ui";
import { readContractCatalog } from "@scm-rft/api-client";
import { AuthMemberPanel } from "./features/auth-member-panel";
import { OrderLotPanel } from "./features/order-lot-panel";

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
  const [currentMemberId, setCurrentMemberId] = useState("");
  const title = formatPortalTitle(describePortalScope("scm-rft"));
  const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? "";
  const orderLotApiBaseUrl = import.meta.env.VITE_ORDER_LOT_API_BASE_URL ?? apiBaseUrl;

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
          The portal now covers Auth and Member flows and extends into the Order-Lot P0 path for
          order search, lot detail, and guarded status change.
        </p>
        <div className="heroMeta">
          <span>Contracts: {catalog.contracts.length}</span>
          <span>Auth/Member base: {apiBaseUrl || "(same origin)"}</span>
          <span>Order-Lot base: {orderLotApiBaseUrl || "(same origin)"}</span>
        </div>
      </header>

      <AuthMemberPanel
        apiBaseUrl={apiBaseUrl}
        accessToken={accessToken}
        onAccessTokenChange={setAccessToken}
        onLoginSuccess={setCurrentMemberId}
      />

      <OrderLotPanel
        apiBaseUrl={orderLotApiBaseUrl}
        accessToken={accessToken}
        changedByHint={currentMemberId}
      />
    </main>
  );
}
