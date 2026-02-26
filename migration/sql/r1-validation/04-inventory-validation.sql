/*
  SCM-213 R1 Domain Validation SQL
  Domain: inventory
  목적: legacy vs target 비교 (count / sum / sample200 / status distribution)

  기본 DB:
    - Legacy : [MES_HI_LEGACY]
    - Target : [MES_HI]

  TODO:
    - legacy DB명이 다르면 [MES_HI_LEGACY]를 실제 DB명으로 변경.
    - legacy inventory_balances / inventory_movements 컬럼명이 다르면 legacy CTE만 수정.
*/

SET NOCOUNT ON;
DECLARE @Domain NVARCHAR(30) = N'inventory';
DECLARE @SampleSize INT = 200;

/* 1) count 비교 (balances + movements) */
WITH legacy_bal AS (
    SELECT item_code, warehouse_code, quantity, updated_at
    FROM [MES_HI_LEGACY].dbo.inventory_balances
),
target_bal AS (
    SELECT item_code, warehouse_code, quantity, updated_at
    FROM [MES_HI].dbo.inventory_balances
),
legacy_mov AS (
    SELECT movement_id, item_code, warehouse_code, movement_type, quantity, moved_at
    FROM [MES_HI_LEGACY].dbo.inventory_movements
),
target_mov AS (
    SELECT movement_id, item_code, warehouse_code, movement_type, quantity, moved_at
    FROM [MES_HI].dbo.inventory_movements
)
SELECT
    @Domain AS domain,
    N'inventory_balances' AS metric,
    (SELECT COUNT_BIG(1) FROM legacy_bal) AS legacy_count,
    (SELECT COUNT_BIG(1) FROM target_bal) AS target_count,
    ABS((SELECT COUNT_BIG(1) FROM target_bal) - (SELECT COUNT_BIG(1) FROM legacy_bal)) AS count_mismatch
UNION ALL
SELECT
    @Domain AS domain,
    N'inventory_movements' AS metric,
    (SELECT COUNT_BIG(1) FROM legacy_mov) AS legacy_count,
    (SELECT COUNT_BIG(1) FROM target_mov) AS target_count,
    ABS((SELECT COUNT_BIG(1) FROM target_mov) - (SELECT COUNT_BIG(1) FROM legacy_mov)) AS count_mismatch;

/* 2) sum 비교 (quantity) + 편차 계산 */
WITH legacy_bal AS (
    SELECT CAST(ISNULL(quantity, 0) AS DECIMAL(38, 6)) AS qty
    FROM [MES_HI_LEGACY].dbo.inventory_balances
),
target_bal AS (
    SELECT CAST(ISNULL(quantity, 0) AS DECIMAL(38, 6)) AS qty
    FROM [MES_HI].dbo.inventory_balances
),
legacy_mov AS (
    SELECT CAST(ISNULL(quantity, 0) AS DECIMAL(38, 6)) AS qty
    FROM [MES_HI_LEGACY].dbo.inventory_movements
),
target_mov AS (
    SELECT CAST(ISNULL(quantity, 0) AS DECIMAL(38, 6)) AS qty
    FROM [MES_HI].dbo.inventory_movements
),
metrics AS (
    SELECT
        N'balance_quantity_sum' AS metric,
        (SELECT CAST(SUM(qty) AS DECIMAL(38, 6)) FROM legacy_bal) AS legacy_sum,
        (SELECT CAST(SUM(qty) AS DECIMAL(38, 6)) FROM target_bal) AS target_sum
    UNION ALL
    SELECT
        N'movement_quantity_sum' AS metric,
        (SELECT CAST(SUM(qty) AS DECIMAL(38, 6)) FROM legacy_mov) AS legacy_sum,
        (SELECT CAST(SUM(qty) AS DECIMAL(38, 6)) FROM target_mov) AS target_sum
)
SELECT
    @Domain AS domain,
    metric,
    legacy_sum,
    target_sum,
    CAST(ABS(target_sum - legacy_sum) AS DECIMAL(38, 6)) AS abs_delta,
    CAST(
        CASE
            WHEN legacy_sum = 0 AND target_sum = 0 THEN 0
            WHEN legacy_sum = 0 THEN 100.0
            ELSE ABS(target_sum - legacy_sum) * 100.0 / ABS(legacy_sum)
        END
        AS DECIMAL(18, 6)
    ) AS delta_pct
FROM metrics;

/* 3) sample 200 비교를 위한 키 추출 (movements 양쪽) + mismatch 계산 */
WITH legacy_base AS (
    SELECT
        CAST(movement_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(movement_id AS NVARCHAR(64)), item_code, warehouse_code, movement_type, quantity, moved_at) AS row_hash
    FROM [MES_HI_LEGACY].dbo.inventory_movements
),
target_base AS (
    SELECT
        CAST(movement_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(movement_id AS NVARCHAR(64)), item_code, warehouse_code, movement_type, quantity, moved_at) AS row_hash
    FROM [MES_HI].dbo.inventory_movements
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
        CAST(movement_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(movement_id AS NVARCHAR(64)), item_code, warehouse_code, movement_type, quantity, moved_at) AS row_hash
    FROM [MES_HI_LEGACY].dbo.inventory_movements
),
target_base AS (
    SELECT
        CAST(movement_id AS NVARCHAR(64)) AS sample_key,
        CHECKSUM(CAST(movement_id AS NVARCHAR(64)), item_code, warehouse_code, movement_type, quantity, moved_at) AS row_hash
    FROM [MES_HI].dbo.inventory_movements
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

/* 4) status 분포 비교 (movement_type) + 편차(%p) */
WITH legacy_dist AS (
    SELECT movement_type AS status_key, COUNT_BIG(1) AS cnt
    FROM [MES_HI_LEGACY].dbo.inventory_movements
    GROUP BY movement_type
),
target_dist AS (
    SELECT movement_type AS status_key, COUNT_BIG(1) AS cnt
    FROM [MES_HI].dbo.inventory_movements
    GROUP BY movement_type
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
