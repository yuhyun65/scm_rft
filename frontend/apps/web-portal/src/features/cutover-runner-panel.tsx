import { useState } from "react";
import { createScmApiClient, formatApiError } from "@scm-rft/api-client";

type CutoverRunnerPanelProps = {
  apiBaseUrl: string;
  accessToken: string;
  memberIdHint?: string;
};

export function pickScenarioMemberId(memberIdHint?: string) {
  return memberIdHint?.trim() ? memberIdHint.trim() : "smoke-user";
}

export function buildRunbookReferences() {
  return [
    "runbooks/rehearsal-R1-runbook.md",
    "runbooks/go-nogo-signoff.md",
    "runbooks/merge-gates-checklist.md",
    "runbooks/today-execution-R1.md",
    "doc/roadmap/scm-201-p0-scenarios.md"
  ];
}

export function CutoverRunnerPanel({
  apiBaseUrl,
  accessToken,
  memberIdHint = ""
}: CutoverRunnerPanelProps) {
  const [errorText, setErrorText] = useState("");
  const [scenarioResult, setScenarioResult] = useState<unknown>(null);
  const [isRunning, setIsRunning] = useState(false);
  const scenarioMemberId = pickScenarioMemberId(memberIdHint);
  const runbookReferences = buildRunbookReferences();

  async function handleRunScenario() {
    if (!accessToken) {
      setErrorText("Run the Auth login flow first so the integrated scenario has a gateway token.");
      return;
    }

    setIsRunning(true);
    setErrorText("");

    try {
      const client = createScmApiClient({ baseUrl: apiBaseUrl, accessToken });
      const summary: Record<string, unknown> = {
        memberId: scenarioMemberId
      };

      const verify = await client.verifyToken(accessToken);
      summary.tokenActive = verify.active;

      const members = await client.searchMembers({
        keyword: scenarioMemberId,
        status: "ACTIVE",
        page: 0,
        size: 10
      });
      summary.memberHits = members.items.length;

      const orders = await client.searchOrders({
        keyword: "P0-ORDER",
        page: 0,
        size: 10
      });
      const orderId = orders.items[0]?.orderId ?? "P0-ORDER-001";
      summary.orderId = orderId;

      const orderDetail = await client.getOrder(orderId);
      summary.orderStatus = orderDetail.status;

      const lotDetail = await client.getLot("P0-LOT-001");
      summary.lotId = lotDetail.lotId;

      const boardPosts = await client.searchBoardPosts({ page: 0, size: 10 });
      const boardPostId = boardPosts.items[0]?.postId;
      summary.boardPostCount = boardPosts.items.length;
      if (boardPostId) {
        const boardDetail = await client.getBoardPost(boardPostId);
        summary.boardPostId = boardDetail.postId;
      }

      const qualityDocs = await client.searchQualityDocuments({ page: 0, size: 10 });
      const documentId = qualityDocs.items[0]?.documentId ?? "11111111-1111-1111-1111-111111111111";
      summary.qualityDocCount = qualityDocs.items.length;
      const qualityDetail = await client.getQualityDocument(documentId);
      summary.qualityDocId = qualityDetail.documentId;
      const ack = await client.acknowledgeQualityDocument(documentId, {
        memberId: scenarioMemberId,
        ackType: "READ",
        comment: "SCM-250 integrated runner"
      });
      summary.qualityDocAcked = ack.acknowledged;
      summary.qualityDocAckDuplicate = ack.duplicateRequest ?? false;

      const balances = await client.searchInventoryBalances({
        itemCode: "ITEM-001",
        page: 0,
        size: 10
      });
      summary.inventoryBalanceCount = balances.items.length;

      const fileMetadata = await client.registerFile({
        domainKey: "P0:CUTOVER",
        originalName: "scm-250-proof.txt",
        storagePath: "frontend/scm-250-proof.txt"
      });
      summary.fileId = fileMetadata.fileId;
      const fileDetail = await client.getFile(fileMetadata.fileId);
      summary.fileDetailId = fileDetail.fileId;

      const reportJob = await client.createReportJob({
        reportType: "P0_DAILY",
        requestedByMemberId: scenarioMemberId
      });
      summary.reportJobId = reportJob.jobId;
      const reportDetail = await client.getReportJob(reportJob.jobId);
      summary.reportStatus = reportDetail.status;

      setScenarioResult(summary);
    } catch (error) {
      setErrorText(formatApiError(error));
    } finally {
      setIsRunning(false);
    }
  }

  return (
    <section className="panel">
      <div className="panelHeader">
        <p className="eyebrow">SCM-250</p>
        <h2>Integrated P0 Runner + Cutover References</h2>
        <p className="panelIntro">
          This panel runs the cross-domain gateway scenario in one shot and keeps the cutover
          runbook references visible inside the portal while the frontend line is hardened.
        </p>
      </div>

      <div className="actionGrid">
        <div className="card">
          <h3>Run P0 Gateway Scenario</h3>
          <p className="hintText">
            Sequence: token verify, member search, order/lot, board, quality-doc ACK, inventory,
            file register/detail, report job create/detail.
          </p>
          <p className="hintText">Scenario member: {scenarioMemberId}</p>
          <button onClick={handleRunScenario} disabled={isRunning}>
            {isRunning ? "Running..." : "Run P0 Gateway Scenario"}
          </button>
          <ResultBlock title="Scenario Summary" value={scenarioResult} />
        </div>

        <div className="card">
          <h3>Cutover References</h3>
          <ul className="referenceList">
            {runbookReferences.map((path) => (
              <li key={path}>
                <code>{path}</code>
              </li>
            ))}
          </ul>
          <p className="hintText">
            Use these files for rehearsal timing, merge gates, and final Go/No-Go signoff.
          </p>
        </div>
      </div>

      {errorText ? <p className="errorBanner">{errorText}</p> : null}
    </section>
  );
}

function ResultBlock({ title, value }: { title: string; value: unknown }) {
  return (
    <details className="resultBlock">
      <summary>{title}</summary>
      <pre>{JSON.stringify(value, null, 2)}</pre>
    </details>
  );
}
