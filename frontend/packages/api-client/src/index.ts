import { contractCatalog } from "./generated/contracts";

export function readContractCatalog() {
  return contractCatalog;
}

export type ApiClientOptions = {
  baseUrl?: string;
  accessToken?: string;
  fetcher?: typeof fetch;
};

type ApiErrorPayload = {
  code?: string;
  message?: string;
  path?: string;
  timestamp?: string;
};

export type LoginRequest = {
  loginId: string;
  password: string;
};

export type LoginResponse = {
  accessToken: string;
  tokenType: string;
  expiresIn: number;
  expiresAt: string;
  memberId: string;
  roles: string[];
};

export type VerifyTokenResponse = {
  active: boolean;
  subject?: string;
  roles?: string[];
  issuedAt?: string;
  expiresAt?: string;
};

export type Member = {
  memberId: string;
  memberName?: string;
  status?: string;
};

export type MemberSearchResponse = {
  items: Member[];
  total: number;
  page: number;
  size: number;
};

export type CreateMemberRequest = {
  memberId: string;
  memberName: string;
  status?: string;
};

export type PageMeta = {
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  hasNext: boolean;
};

export type AttachmentRef = {
  fileId: string;
  fileName?: string;
};

export type BoardPostSummary = {
  postId: string;
  boardType: string;
  title: string;
  status: string;
  createdBy: string;
  createdAt: string;
};

export type BoardPostDetail = BoardPostSummary & {
  content?: string;
  attachments?: AttachmentRef[];
};

export type BoardPostSearchResponse = {
  items: BoardPostSummary[];
  page: PageMeta;
};

export type BoardPostCreateRequest = {
  boardType: string;
  title: string;
  content: string;
  createdBy: string;
  attachments?: Array<{ fileId: string }>;
};

export type BoardPostCreateResponse = {
  postId: string;
  createdAt: string;
};

export type QualityDocumentSummary = {
  documentId: string;
  title: string;
  status: string;
  issuedAt: string;
};

export type QualityDocumentDetail = QualityDocumentSummary & {
  contentUrl?: string | null;
  version?: string | null;
  requiresAck: boolean;
};

export type QualityDocumentSearchResponse = {
  items: QualityDocumentSummary[];
  page: PageMeta;
};

export type QualityDocumentAckRequest = {
  memberId: string;
  ackType: string;
  comment?: string;
};

export type QualityDocumentAckResponse = {
  documentId: string;
  memberId: string;
  ackType: string;
  acknowledged: boolean;
  acknowledgedAt: string;
  duplicateRequest?: boolean;
};

export type InventoryBalance = {
  itemCode: string;
  warehouseCode: string;
  quantity: number;
  updatedAt: string;
};

export type InventoryMovement = {
  movementId: string;
  itemCode: string;
  warehouseCode: string;
  movementType: string;
  quantity: number;
  referenceNo?: string;
  movedAt: string;
};

export type InventoryBalanceSearchResponse = {
  items: InventoryBalance[];
  total: number;
  page: number;
  size: number;
};

export type InventoryMovementSearchResponse = {
  items: InventoryMovement[];
  total: number;
  page: number;
  size: number;
};

export type InventoryAdjustmentRequest = {
  itemCode: string;
  warehouseCode: string;
  quantityDelta: number;
  referenceNo?: string;
};

export type InventoryAdjustmentResponse = {
  movementId: string;
  itemCode: string;
  warehouseCode: string;
  quantityDelta: number;
  resultingQuantity: number;
  referenceNo?: string;
  adjustedAt: string;
};

export type FileRegisterRequest = {
  domainKey: string;
  originalName: string;
  storagePath: string;
};

export type FileMetadata = {
  fileId: string;
  domainKey: string;
  originalName: string;
  storagePath: string;
};

export type RegisterQualityDocumentRequest = {
  title: string;
  documentType: string;
  publisherMemberId?: string;
};

export type ReportJobCreateRequest = {
  reportType: string;
  requestedByMemberId?: string;
};

export type ReportJob = {
  jobId: string;
  reportType: string;
  status: string;
  requestedByMemberId?: string;
  requestedAt: string;
  completedAt?: string | null;
  outputFileId?: string | null;
  errorMessage?: string | null;
};

export type DashboardKpis = {
  activeOrders: number;
  pendingLots: number;
  completedThisWeek: number;
  stockAlertCount: number;
};

export type DashboardDailyCount = {
  day: string;
  date: string;
  count: number;
  accent: boolean;
};

export type DashboardWeeklyOrders = {
  items: DashboardDailyCount[];
  completed: number;
  inProgress: number;
  canceled: number;
};

export type DashboardActivity = {
  icon: string;
  tone: string;
  title: string;
  detail: string;
  occurredAt: string;
};

export type DashboardStockAlert = {
  code: string;
  name: string;
  warehouseCode: string;
  current: number;
  safety: number;
  level: string;
};

export type DashboardSummaryResponse = {
  businessDate: string;
  generatedAt: string;
  kpis: DashboardKpis;
  weeklyOrders: DashboardWeeklyOrders;
  recentActivities: DashboardActivity[];
  stockAlerts: DashboardStockAlert[];
};

export type OrderSummary = {
  orderId: string;
  supplierId: string;
  status: string;
  orderedAt: string;
};

export type OrderSearchResponse = {
  items: OrderSummary[];
  page: PageMeta;
};

export type OrderDetail = {
  orderId: string;
  supplierId: string;
  status: string;
  orderedAt: string;
  expectedDeliveryAt?: string | null;
  totalLotCount?: number | null;
};

export type LotDetail = {
  lotId: string;
  orderId: string;
  quantity: number;
  status: string;
};

export type OrderStatusChangeRequest = {
  targetStatus: string;
  changedBy: string;
  reason?: string;
};

export type OrderStatusChangeResponse = {
  orderId: string;
  beforeStatus: string;
  afterStatus: string;
  changedAt: string;
};

export type CreateOrderRequest = {
  orderId: string;
  supplierId: string;
  orderDate: string;
  status?: string;
};

export type UpdateOrderRequest = {
  supplierId: string;
  orderDate: string;
};

export type AddLotRequest = {
  lotId: string;
  quantity: number;
  status?: string;
};

function normalizeBaseUrl(baseUrl: string): string {
  if (!baseUrl) {
    return "";
  }
  return baseUrl.replace(/\/+$/, "");
}

export class ApiError extends Error {
  status: number;
  code?: string;
  path?: string;
  timestamp?: string;

  constructor(status: number, payload: ApiErrorPayload = {}) {
    super(payload.message ?? `HTTP ${status}`);
    this.name = "ApiError";
    this.status = status;
    this.code = payload.code;
    this.path = payload.path;
    this.timestamp = payload.timestamp;
  }
}

function buildQueryString(query: Record<string, string | number | undefined>): string {
  const params = new URLSearchParams();
  Object.entries(query).forEach(([key, value]) => {
    if (value !== undefined && value !== "") {
      params.set(key, String(value));
    }
  });
  const encoded = params.toString();
  return encoded ? `?${encoded}` : "";
}

async function parsePayload(response: Response): Promise<unknown> {
  const text = await response.text();
  if (!text) {
    return {};
  }

  try {
    return JSON.parse(text);
  } catch {
    return { message: text };
  }
}

export class ScmApiClient {
  private readonly baseUrl: string;
  private accessToken?: string;
  private readonly fetcher: typeof fetch;

  constructor(options: ApiClientOptions = {}) {
    this.baseUrl = normalizeBaseUrl(options.baseUrl ?? "");
    this.accessToken = options.accessToken;
    const rawFetcher = options.fetcher ?? globalThis.fetch;
    this.fetcher = rawFetcher.bind(globalThis);
  }

  setAccessToken(token?: string) {
    this.accessToken = token;
  }

  private async request<TResponse>(
    method: "GET" | "POST" | "PUT",
    path: string,
    body?: unknown
  ): Promise<TResponse> {
    const headers: HeadersInit = {
      "Content-Type": "application/json"
    };
    if (this.accessToken) {
      headers.Authorization = `Bearer ${this.accessToken}`;
    }

    const response = await this.fetcher(`${this.baseUrl}${path}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined
    });

    const payload = (await parsePayload(response)) as ApiErrorPayload | TResponse;
    if (!response.ok) {
      throw new ApiError(response.status, payload as ApiErrorPayload);
    }

    return payload as TResponse;
  }

  login(request: LoginRequest): Promise<LoginResponse> {
    return this.request<LoginResponse>("POST", "/api/auth/v1/login", request);
  }

  verifyToken(accessToken: string): Promise<VerifyTokenResponse> {
    return this.request<VerifyTokenResponse>("POST", "/api/auth/v1/tokens/verify", { accessToken });
  }

  getMember(memberId: string): Promise<Member> {
    return this.request<Member>("GET", `/api/member/v1/members/${encodeURIComponent(memberId)}`);
  }

  searchMembers(params: {
    keyword?: string;
    status?: string;
    page?: number;
    size?: number;
  }): Promise<MemberSearchResponse> {
    const query = buildQueryString({
      keyword: params.keyword,
      status: params.status,
      page: params.page,
      size: params.size
    });
    return this.request<MemberSearchResponse>("GET", `/api/member/v1/members${query}`);
  }

  createMember(request: CreateMemberRequest): Promise<Member> {
    return this.request<Member>("POST", "/api/member/v1/members", request);
  }

  searchOrders(params: {
    supplierId?: string;
    status?: string;
    keyword?: string;
    page?: number;
    size?: number;
  }): Promise<OrderSearchResponse> {
    const query = buildQueryString({
      supplierId: params.supplierId,
      status: params.status,
      keyword: params.keyword,
      page: params.page,
      size: params.size
    });
    return this.request<OrderSearchResponse>("GET", `/api/order-lot/v1/orders${query}`);
  }

  getOrder(orderId: string): Promise<OrderDetail> {
    return this.request<OrderDetail>("GET", `/api/order-lot/v1/orders/${encodeURIComponent(orderId)}`);
  }

  createOrder(request: CreateOrderRequest): Promise<OrderDetail> {
    return this.request<OrderDetail>("POST", "/api/order-lot/v1/orders", request);
  }

  updateOrder(orderId: string, request: UpdateOrderRequest): Promise<OrderDetail> {
    return this.request<OrderDetail>("PUT", `/api/order-lot/v1/orders/${encodeURIComponent(orderId)}`, request);
  }

  getLot(lotId: string): Promise<LotDetail> {
    return this.request<LotDetail>("GET", `/api/order-lot/v1/lots/${encodeURIComponent(lotId)}`);
  }

  addLot(orderId: string, request: AddLotRequest): Promise<LotDetail> {
    return this.request<LotDetail>(
      "POST",
      `/api/order-lot/v1/orders/${encodeURIComponent(orderId)}/lots`,
      request
    );
  }

  changeOrderStatus(
    orderId: string,
    request: OrderStatusChangeRequest
  ): Promise<OrderStatusChangeResponse> {
    return this.request<OrderStatusChangeResponse>(
      "POST",
      `/api/order-lot/v1/orders/${encodeURIComponent(orderId)}/status`,
      request
    );
  }

  searchBoardPosts(params: {
    boardType?: string;
    keyword?: string;
    page?: number;
    size?: number;
  }): Promise<BoardPostSearchResponse> {
    const query = buildQueryString({
      boardType: params.boardType,
      keyword: params.keyword,
      page: params.page,
      size: params.size
    });
    return this.request<BoardPostSearchResponse>("GET", `/api/board/v1/posts${query}`);
  }

  getBoardPost(postId: string): Promise<BoardPostDetail> {
    return this.request<BoardPostDetail>("GET", `/api/board/v1/posts/${encodeURIComponent(postId)}`);
  }

  createBoardPost(request: BoardPostCreateRequest): Promise<BoardPostCreateResponse> {
    return this.request<BoardPostCreateResponse>("POST", "/api/board/v1/posts", request);
  }

  searchQualityDocuments(params: {
    status?: string;
    keyword?: string;
    page?: number;
    size?: number;
  }): Promise<QualityDocumentSearchResponse> {
    const query = buildQueryString({
      status: params.status,
      keyword: params.keyword,
      page: params.page,
      size: params.size
    });
    return this.request<QualityDocumentSearchResponse>("GET", `/api/quality-doc/v1/documents${query}`);
  }

  registerQualityDocument(request: RegisterQualityDocumentRequest): Promise<QualityDocumentDetail> {
    return this.request<QualityDocumentDetail>("POST", "/api/quality-doc/v1/documents", request);
  }

  getQualityDocument(documentId: string): Promise<QualityDocumentDetail> {
    return this.request<QualityDocumentDetail>(
      "GET",
      `/api/quality-doc/v1/documents/${encodeURIComponent(documentId)}`
    );
  }

  acknowledgeQualityDocument(
    documentId: string,
    request: QualityDocumentAckRequest
  ): Promise<QualityDocumentAckResponse> {
    return this.request<QualityDocumentAckResponse>(
      "PUT",
      `/api/quality-doc/v1/documents/${encodeURIComponent(documentId)}/ack`,
      request
    );
  }

  searchInventoryBalances(params: {
    itemCode?: string;
    warehouseCode?: string;
    page?: number;
    size?: number;
  }): Promise<InventoryBalanceSearchResponse> {
    const query = buildQueryString({
      itemCode: params.itemCode,
      warehouseCode: params.warehouseCode,
      page: params.page,
      size: params.size
    });
    return this.request<InventoryBalanceSearchResponse>("GET", `/api/inventory/v1/balances${query}`);
  }

  searchInventoryMovements(params: {
    itemCode?: string;
    warehouseCode?: string;
    movementType?: string;
    page?: number;
    size?: number;
  }): Promise<InventoryMovementSearchResponse> {
    const query = buildQueryString({
      itemCode: params.itemCode,
      warehouseCode: params.warehouseCode,
      movementType: params.movementType,
      page: params.page,
      size: params.size
    });
    return this.request<InventoryMovementSearchResponse>("GET", `/api/inventory/v1/movements${query}`);
  }

  adjustInventory(request: InventoryAdjustmentRequest): Promise<InventoryAdjustmentResponse> {
    return this.request<InventoryAdjustmentResponse>("POST", "/api/inventory/v1/adjustments", request);
  }

  registerFile(request: FileRegisterRequest): Promise<FileMetadata> {
    return this.request<FileMetadata>("POST", "/api/file/v1/files", request);
  }

  getFile(fileId: string): Promise<FileMetadata> {
    return this.request<FileMetadata>("GET", `/api/file/v1/files/${encodeURIComponent(fileId)}`);
  }

  createReportJob(request: ReportJobCreateRequest): Promise<ReportJob> {
    return this.request<ReportJob>("POST", "/api/report/v1/jobs", request);
  }

  getReportJob(jobId: string): Promise<ReportJob> {
    return this.request<ReportJob>("GET", `/api/report/v1/jobs/${encodeURIComponent(jobId)}`);
  }

  getDashboardSummary(): Promise<DashboardSummaryResponse> {
    return this.request<DashboardSummaryResponse>("GET", "/api/dashboard/v1/summary");
  }
}

export function createScmApiClient(options?: ApiClientOptions): ScmApiClient {
  return new ScmApiClient(options);
}

export function formatApiError(error: unknown): string {
  if (error instanceof ApiError) {
    const code = error.code ? ` [${error.code}]` : "";
    return `${error.message}${code}`;
  }
  return String(error);
}
