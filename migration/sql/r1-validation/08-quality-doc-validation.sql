/*
  SCM-213 R1 Domain Validation SQL
  Domain: quality-doc
  목적: legacy vs target 비교 (count / sum / sample200 / status distribution)

  기본 DB:
    - Legacy : [MES_HI_LEGACY]
    - Target : [MES_HI]

  TODO:
    - legacy DB명이 다르면 [MES_HI_LEGACY]를 실제 DB명으로 변경.
    - legacy quality_documents / quality_document_acks 컬럼명이 다르면 legacy CTE만 수정.
*/

SET NOCOUNT ON;
DECLARE @Domain NVARCHAR(30) = N'quality-doc';
DECLARE @SampleSize INT = 200;

/* 1) count 비교 (documents + acks) */
WITH legacy_docs AS (
    SELECT document_id, title, document_type, issued_at, publisher_member_id, status
    FROM [MES_HI_LEGACY].dbo.quality_documents
),
target_docs AS (
    SELECT document_id, title, document_type, issued_at, publisher_member_id, status
    FROM [MES_HI].dbo.quality_documents
),
legacy_acks AS (
    SELECT document_id, member_id, ack_at
    FROM [MES_HI_LEGACY].dbo.quality_document_acks
),
target_acks AS (
    SELECT document_id, member_id, ack_at
    FROM [MES_HI].dbo.quality_document_acks
)
SELECT
    @Domain AS domain,
    N'quality_documents' AS metric,
    (SELECT COUNT_BIG(1) FROM legacy_docs) AS legacy_count,
    (SELECT COUNT_BIG(1) FROM target_docs) AS target_count,
    ABS((SELECT COUNT_BIG(1) FROM target_docs) - (SELECT COUNT_BIG(1) FROM legacy_docs)) AS count_mismatch
UNION ALL
SELECT
    @Domain AS domain,
    N'quality_document_acks' AS metric,
    (SELECT COUNT_BIG(1) FROM legacy_acks) AS legacy_count,
    (SELECT COUNT_BIG(1) FROM target_acks) AS target_count,
    ABS((SELECT COUNT_BIG(1) FROM target_acks) - (SELECT COUNT_BIG(1) FROM legacy_acks)) AS count_mismatch;

/* 2) sum 비교 (ack_count) + 편차 계산 */
WITH legacy_sum AS (
    SELECT CAST(COUNT_BIG(1) AS DECIMAL(38, 6)) AS sum_value
    FROM [MES_HI_LEGACY].dbo.quality_document_acks
),
target_sum AS (
    SELECT CAST(COUNT_BIG(1) AS DECIMAL(38, 6)) AS sum_value
    FROM [MES_HI].dbo.quality_document_acks
)
SELECT
    @Domain AS domain,
    ls.sum_value AS legacy_sum,
    ts.sum_value AS target_sum,
    CAST(ABS(ts.sum_value - ls.sum_value) AS DECIMAL(38, 6)) AS abs_delta,
    CAST(
        CASE
            WHEN ls.sum_value = 0 AND ts.sum_value = 0 THEN 0
            WHEN ls.sum_value = 0 THEN 100.0
            ELSE ABS(ts.sum_value - ls.sum_value) * 100.0 / ABS(ls.sum_value)
        END
        AS DECIMAL(18, 6)
    ) AS delta_pct
FROM legacy_sum ls
CROSS JOIN target_sum ts;

/* 3) sample 200 비교를 위한 키 추출 (documents 양쪽) + mismatch 계산 */
WITH legacy_base AS (
    SELECT
        CAST(document_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(document_id AS NVARCHAR(64)), title, document_type, status, issued_at) AS row_hash
    FROM [MES_HI_LEGACY].dbo.quality_documents
),
target_base AS (
    SELECT
        CAST(document_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(document_id AS NVARCHAR(64)), title, document_type, status, issued_at) AS row_hash
    FROM [MES_HI].dbo.quality_documents
),
legacy_sample AS (
    SELECT TOP (@SampleSize) sample_key, row_hash
    FROM legacy_base
    ORDER BY sample_key
),
target_sample AS (
    SELECT TOP (@SampleSize) sample_key, row_hash
    FROM target_base
    ORDER BY sample_key
)
SELECT
    COALESCE(l.sample_key, t.sample_key) AS sample_key,
    l.row_hash AS legacy_hash,
    t.row_hash AS target_hash,
    CASE WHEN l.row_hash = t.row_hash AND l.sample_key IS NOT NULL AND t.sample_key IS NOT NULL THEN 0 ELSE 1 END AS is_mismatch
FROM legacy_sample l
FULL OUTER JOIN target_sample t
    ON l.sample_key = t.sample_key
ORDER BY sample_key;

WITH legacy_base AS (
    SELECT
        CAST(document_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(document_id AS NVARCHAR(64)), title, document_type, status, issued_at) AS row_hash
    FROM [MES_HI_LEGACY].dbo.quality_documents
),
target_base AS (
    SELECT
        CAST(document_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(document_id AS NVARCHAR(64)), title, document_type, status, issued_at) AS row_hash
    FROM [MES_HI].dbo.quality_documents
),
legacy_sample AS (
    SELECT TOP (@SampleSize) sample_key, row_hash
    FROM legacy_base
    ORDER BY sample_key
),
target_sample AS (
    SELECT TOP (@SampleSize) sample_key, row_hash
    FROM target_base
    ORDER BY sample_key
),
merged AS (
    SELECT
        COALESCE(l.sample_key, t.sample_key) AS sample_key,
        l.row_hash AS legacy_hash,
        t.row_hash AS target_hash
    FROM legacy_sample l
    FULL OUTER JOIN target_sample t
        ON l.sample_key = t.sample_key
)
SELECT
    @Domain AS domain,
    @SampleSize AS sample_size,
    SUM(CASE WHEN legacy_hash = target_hash AND legacy_hash IS NOT NULL AND target_hash IS NOT NULL THEN 0 ELSE 1 END) AS sample_mismatch_count
FROM merged;

/* 4) status 분포 비교 (documents.status) + 편차(%p) */
WITH legacy_dist AS (
    SELECT status AS status_key, COUNT_BIG(1) AS cnt
    FROM [MES_HI_LEGACY].dbo.quality_documents
    GROUP BY status
),
target_dist AS (
    SELECT status AS status_key, COUNT_BIG(1) AS cnt
    FROM [MES_HI].dbo.quality_documents
    GROUP BY status
),
legacy_total AS (
    SELECT SUM(cnt) AS total_cnt FROM legacy_dist
),
target_total AS (
    SELECT SUM(cnt) AS total_cnt FROM target_dist
),
merged AS (
    SELECT
        COALESCE(l.status_key, t.status_key) AS status_key,
        ISNULL(l.cnt, 0) AS legacy_cnt,
        ISNULL(t.cnt, 0) AS target_cnt
    FROM legacy_dist l
    FULL OUTER JOIN target_dist t
        ON l.status_key = t.status_key
)
SELECT
    @Domain AS domain,
    status_key,
    legacy_cnt,
    target_cnt,
    CAST(CASE WHEN lt.total_cnt = 0 THEN 0 ELSE legacy_cnt * 100.0 / lt.total_cnt END AS DECIMAL(18, 6)) AS legacy_pct,
    CAST(CASE WHEN tt.total_cnt = 0 THEN 0 ELSE target_cnt * 100.0 / tt.total_cnt END AS DECIMAL(18, 6)) AS target_pct,
    CAST(ABS(
        (CASE WHEN lt.total_cnt = 0 THEN 0 ELSE legacy_cnt * 100.0 / lt.total_cnt END)
      - (CASE WHEN tt.total_cnt = 0 THEN 0 ELSE target_cnt * 100.0 / tt.total_cnt END)
    ) AS DECIMAL(18, 6)) AS delta_pct_point
FROM merged
CROSS JOIN legacy_total lt
CROSS JOIN target_total tt
ORDER BY status_key;
