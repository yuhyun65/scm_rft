/*
  SCM-213 R1 Domain Validation SQL
  Domain: order-lot
  목적: legacy vs target 비교 (count / sum / sample200 / status distribution)

  기본 DB:
    - Legacy : [MES_HI_LEGACY]
    - Target : [MES_HI]

  TODO:
    - legacy DB명이 다르면 [MES_HI_LEGACY]를 실제 DB명으로 변경.
    - legacy orders/order_lots 키가 다르면 legacy CTE만 수정.
      (현재 가정: orders.order_no, order_lots.lot_no/order_no)
*/

SET NOCOUNT ON;
DECLARE @Domain NVARCHAR(30) = N'order-lot';
DECLARE @SampleSize INT = 200;

/* 1) count 비교 (orders + order_lots) */
WITH legacy_orders AS (
    SELECT order_no, member_id, order_date, status, created_at
    FROM [MES_HI_LEGACY].dbo.orders
),
target_orders AS (
    SELECT order_no, member_id, order_date, status, created_at
    FROM [MES_HI].dbo.orders
),
legacy_lots AS (
    SELECT lot_no, order_no, quantity, status, created_at
    FROM [MES_HI_LEGACY].dbo.order_lots
),
target_lots AS (
    SELECT lot_no, order_no, quantity, status, created_at
    FROM [MES_HI].dbo.order_lots
)
SELECT
    @Domain AS domain,
    N'orders' AS metric,
    (SELECT COUNT_BIG(1) FROM legacy_orders) AS legacy_count,
    (SELECT COUNT_BIG(1) FROM target_orders) AS target_count,
    ABS((SELECT COUNT_BIG(1) FROM target_orders) - (SELECT COUNT_BIG(1) FROM legacy_orders)) AS count_mismatch
UNION ALL
SELECT
    @Domain AS domain,
    N'order_lots' AS metric,
    (SELECT COUNT_BIG(1) FROM legacy_lots) AS legacy_count,
    (SELECT COUNT_BIG(1) FROM target_lots) AS target_count,
    ABS((SELECT COUNT_BIG(1) FROM target_lots) - (SELECT COUNT_BIG(1) FROM legacy_lots)) AS count_mismatch;

/* 2) sum 비교 (order_lots.quantity) + 편차 계산 */
WITH legacy_lots AS (
    SELECT CAST(ISNULL(quantity, 0) AS DECIMAL(38, 6)) AS qty
    FROM [MES_HI_LEGACY].dbo.order_lots
),
target_lots AS (
    SELECT CAST(ISNULL(quantity, 0) AS DECIMAL(38, 6)) AS qty
    FROM [MES_HI].dbo.order_lots
),
legacy_sum AS (
    SELECT CAST(SUM(qty) AS DECIMAL(38, 6)) AS sum_value FROM legacy_lots
),
target_sum AS (
    SELECT CAST(SUM(qty) AS DECIMAL(38, 6)) AS sum_value FROM target_lots
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

/* 3) sample 200 비교를 위한 키 추출 (lots 양쪽) + mismatch 계산 */
WITH legacy_base AS (
    SELECT
        CONCAT(order_no, N'|', lot_no) AS sample_key,
        CHECKSUM(order_no, lot_no, quantity, status) AS row_hash
    FROM [MES_HI_LEGACY].dbo.order_lots
),
target_base AS (
    SELECT
        CONCAT(order_no, N'|', lot_no) AS sample_key,
        CHECKSUM(order_no, lot_no, quantity, status) AS row_hash
    FROM [MES_HI].dbo.order_lots
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
        CONCAT(order_no, N'|', lot_no) AS sample_key,
        CHECKSUM(order_no, lot_no, quantity, status) AS row_hash
    FROM [MES_HI_LEGACY].dbo.order_lots
),
target_base AS (
    SELECT
        CONCAT(order_no, N'|', lot_no) AS sample_key,
        CHECKSUM(order_no, lot_no, quantity, status) AS row_hash
    FROM [MES_HI].dbo.order_lots
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

/* 4) status 분포 비교 (orders.status) + 편차(%p) */
WITH legacy_dist AS (
    SELECT status AS status_key, COUNT_BIG(1) AS cnt
    FROM [MES_HI_LEGACY].dbo.orders
    GROUP BY status
),
target_dist AS (
    SELECT status AS status_key, COUNT_BIG(1) AS cnt
    FROM [MES_HI].dbo.orders
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
