/*
  SCM-213 R1 Domain Validation SQL
  Domain: report
  목적: legacy vs target 비교 (count / sum / sample200 / status distribution)

  기본 DB:
    - Legacy : [MES_HI_LEGACY]
    - Target : [MES_HI]

  TODO:
    - legacy DB명이 다르면 [MES_HI_LEGACY]를 실제 DB명으로 변경.
    - legacy report_jobs 컬럼명이 다르면 legacy_base CTE만 수정.
*/

SET NOCOUNT ON;
DECLARE @Domain NVARCHAR(30) = N'report';
DECLARE @SampleSize INT = 200;

/* 1) count 비교 (양쪽) */
WITH legacy_base AS (
    SELECT job_id, report_type, requested_by_member_id, status, requested_at, completed_at, output_file_id
    FROM [MES_HI_LEGACY].dbo.report_jobs
),
target_base AS (
    SELECT job_id, report_type, requested_by_member_id, status, requested_at, completed_at, output_file_id
    FROM [MES_HI].dbo.report_jobs
),
legacy_count AS (
    SELECT COUNT_BIG(1) AS cnt FROM legacy_base
),
target_count AS (
    SELECT COUNT_BIG(1) AS cnt FROM target_base
)
SELECT
    @Domain AS domain,
    lc.cnt AS legacy_count,
    tc.cnt AS target_count,
    ABS(tc.cnt - lc.cnt) AS count_mismatch
FROM legacy_count lc
CROSS JOIN target_count tc;

/* 2) sum 비교 (FAILED count) + 편차 계산 */
WITH legacy_base AS (
    SELECT CASE WHEN status = N'FAILED' THEN 1 ELSE 0 END AS failed_flag
    FROM [MES_HI_LEGACY].dbo.report_jobs
),
target_base AS (
    SELECT CASE WHEN status = N'FAILED' THEN 1 ELSE 0 END AS failed_flag
    FROM [MES_HI].dbo.report_jobs
),
legacy_sum AS (
    SELECT CAST(SUM(CAST(failed_flag AS DECIMAL(38, 6))) AS DECIMAL(38, 6)) AS sum_value FROM legacy_base
),
target_sum AS (
    SELECT CAST(SUM(CAST(failed_flag AS DECIMAL(38, 6))) AS DECIMAL(38, 6)) AS sum_value FROM target_base
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

/* 3) sample 200 비교를 위한 키 추출 (양쪽) + mismatch 계산 */
WITH legacy_base AS (
    SELECT
        CAST(job_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(job_id AS NVARCHAR(64)), report_type, status, requested_at, completed_at) AS row_hash
    FROM [MES_HI_LEGACY].dbo.report_jobs
),
target_base AS (
    SELECT
        CAST(job_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(job_id AS NVARCHAR(64)), report_type, status, requested_at, completed_at) AS row_hash
    FROM [MES_HI].dbo.report_jobs
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
        CAST(job_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(job_id AS NVARCHAR(64)), report_type, status, requested_at, completed_at) AS row_hash
    FROM [MES_HI_LEGACY].dbo.report_jobs
),
target_base AS (
    SELECT
        CAST(job_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(job_id AS NVARCHAR(64)), report_type, status, requested_at, completed_at) AS row_hash
    FROM [MES_HI].dbo.report_jobs
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

/* 4) status 분포 비교 (status) + 편차(%p) */
WITH legacy_dist AS (
    SELECT status AS status_key, COUNT_BIG(1) AS cnt
    FROM [MES_HI_LEGACY].dbo.report_jobs
    GROUP BY status
),
target_dist AS (
    SELECT status AS status_key, COUNT_BIG(1) AS cnt
    FROM [MES_HI].dbo.report_jobs
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
