SET NOCOUNT ON;

SELECT
    s.name AS table_schema,
    t.name AS table_name,
    SUM(ps.row_count) AS row_count
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
INNER JOIN sys.dm_db_partition_stats ps
    ON ps.object_id = t.object_id
   AND ps.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name
ORDER BY row_count DESC, s.name, t.name;
