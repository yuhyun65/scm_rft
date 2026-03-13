import { useEffect, useRef, useState } from "react";
import {
  createScmApiClient,
  formatApiError,
  type FileMetadata,
  type InventoryBalanceSearchResponse,
  type InventoryMovementSearchResponse,
  type ReportJob
} from "@scm-rft/api-client";

type InventoryFileReportPanelProps = {
  inventoryApiBaseUrl: string;
  fileApiBaseUrl: string;
  reportApiBaseUrl: string;
  accessToken: string;
  memberIdHint?: string;
};

type ResolveTrackedValueArgs = {
  currentValue: string;
  nextHint: string;
  previousHint: string;
};

export function resolveTrackedValue({
  currentValue,
  nextHint,
  previousHint
}: ResolveTrackedValueArgs) {
  if (!nextHint) {
    return currentValue;
  }

  if (!currentValue || currentValue === previousHint) {
    return nextHint;
  }

  return currentValue;
}

export function InventoryFileReportPanel({
  inventoryApiBaseUrl,
  fileApiBaseUrl,
  reportApiBaseUrl,
  accessToken,
  memberIdHint = ""
}: InventoryFileReportPanelProps) {
  const [itemCode, setItemCode] = useState("ITEM-001");
  const [warehouseCode, setWarehouseCode] = useState("");
  const [inventoryPage, setInventoryPage] = useState("0");
  const [inventorySize, setInventorySize] = useState("10");
  const [movementType, setMovementType] = useState("");
  const [fileId, setFileId] = useState("");
  const [domainKey, setDomainKey] = useState("P0:BOARD");
  const [originalName, setOriginalName] = useState("frontend-proof.txt");
  const [storagePath, setStoragePath] = useState("frontend/frontend-proof.txt");
  const [reportType, setReportType] = useState("P0_DAILY");
  const [requestedByMemberId, setRequestedByMemberId] = useState(memberIdHint);
  const [jobId, setJobId] = useState("");
  const [errorText, setErrorText] = useState("");
  const [balanceResult, setBalanceResult] = useState<InventoryBalanceSearchResponse | null>(null);
  const [movementResult, setMovementResult] = useState<InventoryMovementSearchResponse | null>(null);
  const [fileRegisterResult, setFileRegisterResult] = useState<FileMetadata | null>(null);
  const [fileDetailResult, setFileDetailResult] = useState<FileMetadata | null>(null);
  const [reportCreateResult, setReportCreateResult] = useState<ReportJob | null>(null);
  const [reportDetailResult, setReportDetailResult] = useState<ReportJob | null>(null);
  const previousRequestedByHintRef = useRef(memberIdHint);

  useEffect(() => {
    setRequestedByMemberId((currentValue) =>
      resolveTrackedValue({
        currentValue,
        nextHint: memberIdHint,
        previousHint: previousRequestedByHintRef.current
      })
    );
    previousRequestedByHintRef.current = memberIdHint;
  }, [memberIdHint]);

  async function run<T>(action: () => Promise<T>, onSuccess: (result: T) => void) {
    setErrorText("");
    try {
      const result = await action();
      onSuccess(result);
    } catch (error) {
      setErrorText(formatApiError(error));
    }
  }

  function buildInventoryClient() {
    return createScmApiClient({ baseUrl: inventoryApiBaseUrl, accessToken });
  }

  function buildFileClient() {
    return createScmApiClient({ baseUrl: fileApiBaseUrl, accessToken });
  }

  function buildReportClient() {
    return createScmApiClient({ baseUrl: reportApiBaseUrl, accessToken });
  }

  async function handleSearchBalances() {
    await run(
      () =>
        buildInventoryClient().searchInventoryBalances({
          itemCode,
          warehouseCode,
          page: Number(inventoryPage || "0"),
          size: Number(inventorySize || "10")
        }),
      setBalanceResult
    );
  }

  async function handleSearchMovements() {
    await run(
      () =>
        buildInventoryClient().searchInventoryMovements({
          itemCode,
          warehouseCode,
          movementType,
          page: Number(inventoryPage || "0"),
          size: Number(inventorySize || "10")
        }),
      setMovementResult
    );
  }

  async function handleRegisterFile() {
    await run(
      () =>
        buildFileClient().registerFile({
          domainKey,
          originalName,
          storagePath
        }),
      (result) => {
        setFileRegisterResult(result);
        setFileId(result.fileId);
      }
    );
  }

  async function handleGetFile() {
    await run(() => buildFileClient().getFile(fileId), setFileDetailResult);
  }

  async function handleCreateReportJob() {
    await run(
      () =>
        buildReportClient().createReportJob({
          reportType,
          requestedByMemberId
        }),
      (result) => {
        setReportCreateResult(result);
        setJobId(result.jobId);
      }
    );
  }

  async function handleGetReportJob() {
    await run(() => buildReportClient().getReportJob(jobId), setReportDetailResult);
  }

  return (
    <section className="panel">
      <div className="panelHeader">
        <p className="eyebrow">SCM-249</p>
        <h2>Inventory + File + Report UI MVP</h2>
        <p className="panelIntro">
          Inventory stays read-only, file focuses on metadata registration and lookup, and report
          covers job create plus status polling to complete the portal-side P0 toolbox.
        </p>
      </div>

      <div className="actionGrid">
        <div className="card">
          <h3>Inventory Balances</h3>
          <label>
            Item Code
            <input value={itemCode} onChange={(event) => setItemCode(event.target.value)} />
          </label>
          <label>
            Warehouse Code
            <input
              value={warehouseCode}
              onChange={(event) => setWarehouseCode(event.target.value)}
            />
          </label>
          <div className="inlineFields">
            <label>
              Page
              <input
                value={inventoryPage}
                onChange={(event) => setInventoryPage(event.target.value)}
              />
            </label>
            <label>
              Size
              <input
                value={inventorySize}
                onChange={(event) => setInventorySize(event.target.value)}
              />
            </label>
          </div>
          <button onClick={handleSearchBalances}>Search Balances</button>
          <ResultBlock title="Inventory Balance Response" value={balanceResult} />
        </div>

        <div className="card">
          <h3>Inventory Movements</h3>
          <label>
            Movement Type
            <select value={movementType} onChange={(event) => setMovementType(event.target.value)}>
              <option value="">ALL</option>
              <option value="IN">IN</option>
              <option value="OUT">OUT</option>
              <option value="ADJUST">ADJUST</option>
            </select>
          </label>
          <p className="hintText">
            Uses the same `itemCode`, `warehouseCode`, `page`, and `size` inputs as balance search.
          </p>
          <button onClick={handleSearchMovements}>Search Movements</button>
          <ResultBlock title="Inventory Movement Response" value={movementResult} />
        </div>

        <div className="card">
          <h3>File Register</h3>
          <label>
            Domain Key
            <input value={domainKey} onChange={(event) => setDomainKey(event.target.value)} />
          </label>
          <label>
            Original Name
            <input
              value={originalName}
              onChange={(event) => setOriginalName(event.target.value)}
            />
          </label>
          <label>
            Storage Path
            <input value={storagePath} onChange={(event) => setStoragePath(event.target.value)} />
          </label>
          <button onClick={handleRegisterFile}>Register File Metadata</button>
          <ResultBlock title="File Register Response" value={fileRegisterResult} />
        </div>

        <div className="card">
          <h3>File Detail</h3>
          <label>
            File ID
            <input value={fileId} onChange={(event) => setFileId(event.target.value)} />
          </label>
          <button onClick={handleGetFile}>Get File</button>
          <ResultBlock title="File Detail Response" value={fileDetailResult} />
        </div>

        <div className="card">
          <h3>Report Job Create</h3>
          <label>
            Report Type
            <input value={reportType} onChange={(event) => setReportType(event.target.value)} />
          </label>
          <label>
            Requested By
            <input
              value={requestedByMemberId}
              onChange={(event) => setRequestedByMemberId(event.target.value)}
            />
          </label>
          <button onClick={handleCreateReportJob}>Create Job</button>
          <ResultBlock title="Report Create Response" value={reportCreateResult} />
        </div>

        <div className="card">
          <h3>Report Job Detail</h3>
          <label>
            Job ID
            <input value={jobId} onChange={(event) => setJobId(event.target.value)} />
          </label>
          <button onClick={handleGetReportJob}>Get Job</button>
          <ResultBlock title="Report Detail Response" value={reportDetailResult} />
        </div>
      </div>

      {!accessToken ? (
        <p className="warningBanner">
          Inventory, file, and report requests are expected to run with a gateway token. Login in
          the Auth panel first for realistic authorization behavior.
        </p>
      ) : null}

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
