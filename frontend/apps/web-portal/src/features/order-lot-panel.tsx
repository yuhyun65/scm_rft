import { useEffect, useState } from "react";
import {
  createScmApiClient,
  formatApiError,
  type LotDetail,
  type OrderDetail,
  type OrderSearchResponse,
  type OrderStatusChangeResponse
} from "@scm-rft/api-client";

type OrderLotPanelProps = {
  apiBaseUrl: string;
  accessToken: string;
  changedByHint?: string;
};

export function OrderLotPanel({
  apiBaseUrl,
  accessToken,
  changedByHint = ""
}: OrderLotPanelProps) {
  const [supplierId, setSupplierId] = useState("");
  const [status, setStatus] = useState("");
  const [keyword, setKeyword] = useState("");
  const [page, setPage] = useState("0");
  const [size, setSize] = useState("20");
  const [orderId, setOrderId] = useState("");
  const [lotId, setLotId] = useState("");
  const [targetStatus, setTargetStatus] = useState("CONFIRMED");
  const [changedBy, setChangedBy] = useState(changedByHint);
  const [reason, setReason] = useState("");
  const [errorText, setErrorText] = useState("");
  const [searchResult, setSearchResult] = useState<OrderSearchResponse | null>(null);
  const [orderResult, setOrderResult] = useState<OrderDetail | null>(null);
  const [lotResult, setLotResult] = useState<LotDetail | null>(null);
  const [statusResult, setStatusResult] = useState<OrderStatusChangeResponse | null>(null);

  useEffect(() => {
    if (!changedBy && changedByHint) {
      setChangedBy(changedByHint);
    }
  }, [changedBy, changedByHint]);

  async function run<T>(action: () => Promise<T>, onSuccess: (result: T) => void) {
    setErrorText("");
    try {
      const result = await action();
      onSuccess(result);
    } catch (error) {
      setErrorText(formatApiError(error));
    }
  }

  function buildClient() {
    return createScmApiClient({ baseUrl: apiBaseUrl, accessToken });
  }

  async function handleSearchOrders() {
    await run(
      () =>
        buildClient().searchOrders({
          supplierId,
          status,
          keyword,
          page: Number(page || "0"),
          size: Number(size || "20")
        }),
      setSearchResult
    );
  }

  async function handleGetOrder() {
    await run(() => buildClient().getOrder(orderId), setOrderResult);
  }

  async function handleGetLot() {
    await run(() => buildClient().getLot(lotId), setLotResult);
  }

  async function handleChangeStatus() {
    await run(
      () =>
        buildClient().changeOrderStatus(orderId, {
          targetStatus,
          changedBy,
          reason
        }),
      setStatusResult
    );
  }

  return (
    <section className="panel">
      <div className="panelHeader">
        <p className="eyebrow">SCM-247</p>
        <h2>Order-Lot P0 UI MVP</h2>
        <p className="panelIntro">
          This slice covers order list/detail, lot detail, and a guarded status change flow. Write
          requests are single-shot only. If status change fails, refresh detail before trying
          again.
        </p>
      </div>

      <div className="writeGuard">
        <strong>Write guard:</strong> automatic retry is disabled for order status changes.
      </div>

      <div className="actionGrid">
        <div className="card">
          <h3>Order Search</h3>
          <label>
            Supplier ID
            <input value={supplierId} onChange={(event) => setSupplierId(event.target.value)} />
          </label>
          <label>
            Status
            <select value={status} onChange={(event) => setStatus(event.target.value)}>
              <option value="">ALL</option>
              <option value="PENDING">PENDING</option>
              <option value="CONFIRMED">CONFIRMED</option>
              <option value="IN_PROGRESS">IN_PROGRESS</option>
              <option value="COMPLETED">COMPLETED</option>
              <option value="CANCELED">CANCELED</option>
            </select>
          </label>
          <label>
            Keyword
            <input value={keyword} onChange={(event) => setKeyword(event.target.value)} />
          </label>
          <div className="inlineFields">
            <label>
              Page
              <input value={page} onChange={(event) => setPage(event.target.value)} />
            </label>
            <label>
              Size
              <input value={size} onChange={(event) => setSize(event.target.value)} />
            </label>
          </div>
          <button onClick={handleSearchOrders}>Search Orders</button>
          <ResultBlock title="Order Search Response" value={searchResult} />
        </div>

        <div className="card">
          <h3>Order Detail</h3>
          <label>
            Order ID
            <input value={orderId} onChange={(event) => setOrderId(event.target.value)} />
          </label>
          <div className="buttonRow">
            <button onClick={handleGetOrder}>Get Order</button>
            <button className="ghostButton" onClick={() => setOrderId("")}>
              Clear
            </button>
          </div>
          <ResultBlock title="Order Detail Response" value={orderResult} />
        </div>

        <div className="card">
          <h3>Lot Detail</h3>
          <label>
            Lot ID
            <input value={lotId} onChange={(event) => setLotId(event.target.value)} />
          </label>
          <button onClick={handleGetLot}>Get Lot</button>
          <ResultBlock title="Lot Detail Response" value={lotResult} />
        </div>

        <div className="card">
          <h3>Order Status Change</h3>
          <label>
            Order ID
            <input value={orderId} onChange={(event) => setOrderId(event.target.value)} />
          </label>
          <label>
            Target Status
            <select value={targetStatus} onChange={(event) => setTargetStatus(event.target.value)}>
              <option value="CONFIRMED">CONFIRMED</option>
              <option value="IN_PROGRESS">IN_PROGRESS</option>
              <option value="COMPLETED">COMPLETED</option>
              <option value="CANCELED">CANCELED</option>
            </select>
          </label>
          <label>
            Changed By
            <input value={changedBy} onChange={(event) => setChangedBy(event.target.value)} />
          </label>
          <label>
            Reason
            <textarea
              rows={3}
              value={reason}
              onChange={(event) => setReason(event.target.value)}
            />
          </label>
          <button onClick={handleChangeStatus}>Change Status</button>
          <p className="hintText">Use a fresh detail read before each write attempt.</p>
          <ResultBlock title="Status Change Response" value={statusResult} />
        </div>
      </div>

      {!accessToken ? (
        <p className="warningBanner">
          Order-Lot requests are expected to run with a gateway token. Login in the Auth panel
          first unless you are targeting a local direct service URL.
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
