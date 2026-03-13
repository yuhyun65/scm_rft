import { useEffect, useRef, useState } from "react";
import {
  createScmApiClient,
  formatApiError,
  type AttachmentRef,
  type BoardPostCreateResponse,
  type BoardPostDetail,
  type BoardPostSearchResponse,
  type QualityDocumentAckResponse,
  type QualityDocumentDetail,
  type QualityDocumentSearchResponse
} from "@scm-rft/api-client";

type BoardQualityDocPanelProps = {
  boardApiBaseUrl: string;
  qualityDocApiBaseUrl: string;
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

export function parseAttachmentRefs(rawValue: string): AttachmentRef[] {
  if (!rawValue.trim()) {
    return [];
  }

  return rawValue
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const [fileId, fileName] = line.split("|").map((part) => part.trim());
      return fileName ? { fileId, fileName } : { fileId };
    });
}

export function BoardQualityDocPanel({
  boardApiBaseUrl,
  qualityDocApiBaseUrl,
  accessToken,
  memberIdHint = ""
}: BoardQualityDocPanelProps) {
  const [boardType, setBoardType] = useState("");
  const [boardKeyword, setBoardKeyword] = useState("");
  const [boardPage, setBoardPage] = useState("0");
  const [boardSize, setBoardSize] = useState("10");
  const [postId, setPostId] = useState("");
  const [createBoardType, setCreateBoardType] = useState("GENERAL");
  const [createTitle, setCreateTitle] = useState("");
  const [createContent, setCreateContent] = useState("");
  const [createdBy, setCreatedBy] = useState(memberIdHint);
  const [attachmentRefsText, setAttachmentRefsText] = useState("");
  const [documentStatus, setDocumentStatus] = useState("");
  const [documentKeyword, setDocumentKeyword] = useState("");
  const [documentPage, setDocumentPage] = useState("0");
  const [documentSize, setDocumentSize] = useState("10");
  const [documentId, setDocumentId] = useState("");
  const [ackMemberId, setAckMemberId] = useState(memberIdHint);
  const [ackType, setAckType] = useState("READ");
  const [ackComment, setAckComment] = useState("");
  const [errorText, setErrorText] = useState("");
  const [boardSearchResult, setBoardSearchResult] = useState<BoardPostSearchResponse | null>(null);
  const [boardDetailResult, setBoardDetailResult] = useState<BoardPostDetail | null>(null);
  const [boardCreateResult, setBoardCreateResult] = useState<BoardPostCreateResponse | null>(null);
  const [qualitySearchResult, setQualitySearchResult] =
    useState<QualityDocumentSearchResponse | null>(null);
  const [qualityDetailResult, setQualityDetailResult] = useState<QualityDocumentDetail | null>(null);
  const [qualityAckResult, setQualityAckResult] = useState<QualityDocumentAckResponse | null>(null);
  const previousCreatedByHintRef = useRef(memberIdHint);
  const previousAckMemberIdHintRef = useRef(memberIdHint);

  useEffect(() => {
    setCreatedBy((currentValue) =>
      resolveTrackedValue({
        currentValue,
        nextHint: memberIdHint,
        previousHint: previousCreatedByHintRef.current
      })
    );
    previousCreatedByHintRef.current = memberIdHint;

    setAckMemberId((currentValue) =>
      resolveTrackedValue({
        currentValue,
        nextHint: memberIdHint,
        previousHint: previousAckMemberIdHintRef.current
      })
    );
    previousAckMemberIdHintRef.current = memberIdHint;
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

  function buildBoardClient() {
    return createScmApiClient({ baseUrl: boardApiBaseUrl, accessToken });
  }

  function buildQualityDocClient() {
    return createScmApiClient({ baseUrl: qualityDocApiBaseUrl, accessToken });
  }

  async function handleSearchBoardPosts() {
    await run(
      () =>
        buildBoardClient().searchBoardPosts({
          boardType,
          keyword: boardKeyword,
          page: Number(boardPage || "0"),
          size: Number(boardSize || "10")
        }),
      setBoardSearchResult
    );
  }

  async function handleGetBoardPost() {
    await run(() => buildBoardClient().getBoardPost(postId), setBoardDetailResult);
  }

  async function handleCreateBoardPost() {
    await run(
      () =>
        buildBoardClient().createBoardPost({
          boardType: createBoardType,
          title: createTitle,
          content: createContent,
          createdBy,
          attachments: parseAttachmentRefs(attachmentRefsText).map(({ fileId }) => ({ fileId }))
        }),
      (result) => {
        setBoardCreateResult(result);
        setPostId(result.postId);
      }
    );
  }

  async function handleSearchQualityDocuments() {
    await run(
      () =>
        buildQualityDocClient().searchQualityDocuments({
          status: documentStatus,
          keyword: documentKeyword,
          page: Number(documentPage || "0"),
          size: Number(documentSize || "10")
        }),
      setQualitySearchResult
    );
  }

  async function handleGetQualityDocument() {
    await run(() => buildQualityDocClient().getQualityDocument(documentId), setQualityDetailResult);
  }

  async function handleAcknowledgeDocument() {
    await run(
      () =>
        buildQualityDocClient().acknowledgeQualityDocument(documentId, {
          memberId: ackMemberId,
          ackType,
          comment: ackComment
        }),
      setQualityAckResult
    );
  }

  return (
    <section className="panel">
      <div className="panelHeader">
        <p className="eyebrow">SCM-248</p>
        <h2>Board + Quality-Doc UI MVP</h2>
        <p className="panelIntro">
          Board covers list, detail, and post creation with file-service attachment references.
          Quality-Doc covers list, detail, and idempotent ACK so audit behavior is visible in the
          portal.
        </p>
      </div>

      <div className="actionGrid">
        <div className="card">
          <h3>Board Search</h3>
          <label>
            Board Type
            <select value={boardType} onChange={(event) => setBoardType(event.target.value)}>
              <option value="">ALL</option>
              <option value="NOTICE">NOTICE</option>
              <option value="GENERAL">GENERAL</option>
              <option value="QUALITY">QUALITY</option>
            </select>
          </label>
          <label>
            Keyword
            <input value={boardKeyword} onChange={(event) => setBoardKeyword(event.target.value)} />
          </label>
          <div className="inlineFields">
            <label>
              Page
              <input value={boardPage} onChange={(event) => setBoardPage(event.target.value)} />
            </label>
            <label>
              Size
              <input value={boardSize} onChange={(event) => setBoardSize(event.target.value)} />
            </label>
          </div>
          <button onClick={handleSearchBoardPosts}>Search Posts</button>
          <ResultBlock title="Board Search Response" value={boardSearchResult} />
        </div>

        <div className="card">
          <h3>Board Detail</h3>
          <label>
            Post ID
            <input value={postId} onChange={(event) => setPostId(event.target.value)} />
          </label>
          <button onClick={handleGetBoardPost}>Get Post</button>
          <ResultBlock title="Board Detail Response" value={boardDetailResult} />
        </div>

        <div className="card">
          <h3>Create Board Post</h3>
          <label>
            Board Type
            <select
              value={createBoardType}
              onChange={(event) => setCreateBoardType(event.target.value)}
            >
              <option value="GENERAL">GENERAL</option>
              <option value="NOTICE">NOTICE</option>
              <option value="QUALITY">QUALITY</option>
            </select>
          </label>
          <label>
            Title
            <input value={createTitle} onChange={(event) => setCreateTitle(event.target.value)} />
          </label>
          <label>
            Content
            <textarea
              rows={4}
              value={createContent}
              onChange={(event) => setCreateContent(event.target.value)}
            />
          </label>
          <label>
            Created By
            <input value={createdBy} onChange={(event) => setCreatedBy(event.target.value)} />
          </label>
          <label>
            Attachment File IDs
            <textarea
              rows={4}
              value={attachmentRefsText}
              onChange={(event) => setAttachmentRefsText(event.target.value)}
              placeholder={"one UUID per line\nor UUID|optional file name"}
            />
          </label>
          <p className="hintText">
            Attachment input models file-service linkage only. Each line maps to one `fileId`.
          </p>
          <button onClick={handleCreateBoardPost}>Create Post</button>
          <ResultBlock title="Board Create Response" value={boardCreateResult} />
        </div>

        <div className="card">
          <h3>Quality-Doc Search</h3>
          <label>
            Status
            <select
              value={documentStatus}
              onChange={(event) => setDocumentStatus(event.target.value)}
            >
              <option value="">ALL</option>
              <option value="ACTIVE">ACTIVE</option>
              <option value="EXPIRED">EXPIRED</option>
              <option value="ARCHIVED">ARCHIVED</option>
            </select>
          </label>
          <label>
            Keyword
            <input
              value={documentKeyword}
              onChange={(event) => setDocumentKeyword(event.target.value)}
            />
          </label>
          <div className="inlineFields">
            <label>
              Page
              <input
                value={documentPage}
                onChange={(event) => setDocumentPage(event.target.value)}
              />
            </label>
            <label>
              Size
              <input
                value={documentSize}
                onChange={(event) => setDocumentSize(event.target.value)}
              />
            </label>
          </div>
          <button onClick={handleSearchQualityDocuments}>Search Documents</button>
          <ResultBlock title="Quality-Doc Search Response" value={qualitySearchResult} />
        </div>

        <div className="card">
          <h3>Quality-Doc Detail</h3>
          <label>
            Document ID
            <input value={documentId} onChange={(event) => setDocumentId(event.target.value)} />
          </label>
          <button onClick={handleGetQualityDocument}>Get Document</button>
          <ResultBlock title="Quality-Doc Detail Response" value={qualityDetailResult} />
        </div>

        <div className="card">
          <h3>Quality-Doc ACK</h3>
          <label>
            Document ID
            <input value={documentId} onChange={(event) => setDocumentId(event.target.value)} />
          </label>
          <label>
            Member ID
            <input value={ackMemberId} onChange={(event) => setAckMemberId(event.target.value)} />
          </label>
          <label>
            Ack Type
            <select value={ackType} onChange={(event) => setAckType(event.target.value)}>
              <option value="READ">READ</option>
              <option value="CONFIRMED">CONFIRMED</option>
            </select>
          </label>
          <label>
            Comment
            <textarea
              rows={3}
              value={ackComment}
              onChange={(event) => setAckComment(event.target.value)}
            />
          </label>
          <p className="hintText">
            ACK is idempotent. Repeating the same `documentId/memberId/ackType` should return the
            same logical result.
          </p>
          <button onClick={handleAcknowledgeDocument}>Acknowledge Document</button>
          <ResultBlock title="Quality-Doc ACK Response" value={qualityAckResult} />
        </div>
      </div>

      {!accessToken ? (
        <p className="warningBanner">
          Board and Quality-Doc flows are expected to run with a gateway token. Login in the Auth
          panel first for realistic authorization behavior.
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
