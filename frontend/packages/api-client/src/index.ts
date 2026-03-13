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
export type PageMeta = {
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  hasNext: boolean;
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
    this.fetcher = options.fetcher ?? fetch;
  }

  setAccessToken(token?: string) {
    this.accessToken = token;
  }

  private async request<TResponse>(
    method: "GET" | "POST",
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

  getLot(lotId: string): Promise<LotDetail> {
    return this.request<LotDetail>("GET", `/api/order-lot/v1/lots/${encodeURIComponent(lotId)}`);
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
