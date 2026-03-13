import { useState } from "react";
import {
  createScmApiClient,
  formatApiError,
  type LoginResponse,
  type Member,
  type MemberSearchResponse,
  type VerifyTokenResponse
} from "@scm-rft/api-client";

type AuthMemberPanelProps = {
  apiBaseUrl: string;
  accessToken: string;
  onAccessTokenChange: (token: string) => void;
};

export function AuthMemberPanel({
  apiBaseUrl,
  accessToken,
  onAccessTokenChange
}: AuthMemberPanelProps) {
  const [loginId, setLoginId] = useState("demo");
  const [password, setPassword] = useState("password");
  const [memberId, setMemberId] = useState("");
  const [keyword, setKeyword] = useState("");
  const [status, setStatus] = useState("");
  const [errorText, setErrorText] = useState("");
  const [loginResult, setLoginResult] = useState<LoginResponse | null>(null);
  const [verifyResult, setVerifyResult] = useState<VerifyTokenResponse | null>(null);
  const [memberResult, setMemberResult] = useState<Member | null>(null);
  const [searchResult, setSearchResult] = useState<MemberSearchResponse | null>(null);

  async function run<T>(action: () => Promise<T>, onSuccess: (result: T) => void) {
    setErrorText("");
    try {
      const result = await action();
      onSuccess(result);
    } catch (error) {
      setErrorText(formatApiError(error));
    }
  }

  async function handleLogin() {
    const client = createScmApiClient({ baseUrl: apiBaseUrl });
    await run(
      () => client.login({ loginId, password }),
      (result) => {
        onAccessTokenChange(result.accessToken);
        setLoginResult(result);
      }
    );
  }

  async function handleVerify() {
    const client = createScmApiClient({ baseUrl: apiBaseUrl });
    await run(() => client.verifyToken(accessToken), setVerifyResult);
  }

  async function handleGetMember() {
    const client = createScmApiClient({ baseUrl: apiBaseUrl, accessToken });
    await run(() => client.getMember(memberId), setMemberResult);
  }

  async function handleSearchMembers() {
    const client = createScmApiClient({ baseUrl: apiBaseUrl, accessToken });
    await run(
      () => client.searchMembers({ keyword, status, page: 0, size: 20 }),
      setSearchResult
    );
  }

  return (
    <section className="panel">
      <div className="panelHeader">
        <p className="eyebrow">SCM-246</p>
        <h2>Auth + Member UI MVP</h2>
        <p className="panelIntro">
          Gateway token issued by Auth is reused for Member 조회/검색. Error payload is surfaced
          with backend code and message.
        </p>
      </div>

      <div className="actionGrid">
        <div className="card">
          <h3>Login</h3>
          <label>
            Login ID
            <input value={loginId} onChange={(event) => setLoginId(event.target.value)} />
          </label>
          <label>
            Password
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </label>
          <button onClick={handleLogin}>Login</button>
          <ResultBlock title="Login Response" value={loginResult} />
        </div>

        <div className="card">
          <h3>Token Verify</h3>
          <label>
            Access Token
            <textarea
              rows={5}
              value={accessToken}
              onChange={(event) => onAccessTokenChange(event.target.value)}
            />
          </label>
          <div className="buttonRow">
            <button onClick={handleVerify}>Verify Token</button>
            <button className="ghostButton" onClick={() => onAccessTokenChange("")}>
              Clear Token
            </button>
          </div>
          <ResultBlock title="Verify Response" value={verifyResult} />
        </div>

        <div className="card">
          <h3>Member By ID</h3>
          <label>
            Member ID
            <input value={memberId} onChange={(event) => setMemberId(event.target.value)} />
          </label>
          <button onClick={handleGetMember}>Get Member</button>
          <ResultBlock title="Member Response" value={memberResult} />
        </div>

        <div className="card">
          <h3>Member Search</h3>
          <label>
            Keyword
            <input value={keyword} onChange={(event) => setKeyword(event.target.value)} />
          </label>
          <label>
            Status
            <select value={status} onChange={(event) => setStatus(event.target.value)}>
              <option value="">ALL</option>
              <option value="ACTIVE">ACTIVE</option>
              <option value="INACTIVE">INACTIVE</option>
            </select>
          </label>
          <button onClick={handleSearchMembers}>Search Members</button>
          <ResultBlock title="Search Response" value={searchResult} />
        </div>
      </div>

      {errorText ? <p className="errorBanner">{errorText}</p> : null}
    </section>
  );
}

function ResultBlock({
  title,
  value
}: {
  title: string;
  value: LoginResponse | VerifyTokenResponse | Member | MemberSearchResponse | null;
}) {
  return (
    <details className="resultBlock">
      <summary>{title}</summary>
      <pre>{JSON.stringify(value, null, 2)}</pre>
    </details>
  );
}
