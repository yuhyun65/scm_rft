import { useEffect, useState } from "react";
import { describePortalScope } from "@scm-rft/ui";
import { readContractCatalog } from "@scm-rft/api-client";
import { AuthMemberPanel } from "./features/auth-member-panel";
import { BoardQualityDocPanel } from "./features/board-qualitydoc-panel";
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
  const boardApiBaseUrl = import.meta.env.VITE_BOARD_API_BASE_URL ?? apiBaseUrl;
  const qualityDocApiBaseUrl = import.meta.env.VITE_QUALITY_DOC_API_BASE_URL ?? apiBaseUrl;
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
          The portal now covers Auth, Member, Board, Quality-Doc, and Order-Lot MVP paths so the
          main P0 workflows can be exercised against the gateway from one surface.
        </p>
        <div className="heroMeta">
          <span>Contracts: {catalog.contracts.length}</span>
          <span>Auth/Member base: {apiBaseUrl || "(same origin)"}</span>
          <span>Board base: {boardApiBaseUrl || "(same origin)"}</span>
          <span>Quality-Doc base: {qualityDocApiBaseUrl || "(same origin)"}</span>
          <span>Order-Lot base: {orderLotApiBaseUrl || "(same origin)"}</span>
        </div>
      </header>

      <AuthMemberPanel
        apiBaseUrl={apiBaseUrl}
        accessToken={accessToken}
        onAccessTokenChange={setAccessToken}
        onLoginSuccess={setCurrentMemberId}
      />

      <BoardQualityDocPanel
        boardApiBaseUrl={boardApiBaseUrl}
        qualityDocApiBaseUrl={qualityDocApiBaseUrl}
        accessToken={accessToken}
        memberIdHint={currentMemberId}
      />

      <OrderLotPanel
        apiBaseUrl={orderLotApiBaseUrl}
        accessToken={accessToken}
        changedByHint={currentMemberId}
      />
    </main>
  );
}
