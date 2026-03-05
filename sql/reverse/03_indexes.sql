SET NOCOUNT ON;

SELECT
    s.name AS table_schema,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    i.is_unique,
    i.is_primary_key,
    i.is_unique_constraint,
    i.fill_factor,
    i.has_filter,
    i.filter_definition,
    key_cols.key_columns,
    include_cols.included_columns
FROM sys.indexes i
INNER JOIN sys.tables t
    ON t.object_id = i.object_id
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
OUTER APPLY (
    SELECT STRING_AGG(QUOTENAME(c.name) + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END, ', ')
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns
    FROM sys.index_columns ic
    INNER JOIN sys.columns c
        ON c.object_id = ic.object_id
       AND c.column_id = ic.column_id
    WHERE ic.object_id = i.object_id
      AND ic.index_id = i.index_id
      AND ic.key_ordinal > 0
      AND ic.is_included_column = 0
) key_cols
OUTER APPLY (
    SELECT STRING_AGG(QUOTENAME(c.name), ', ')
        WITHIN GROUP (ORDER BY ic.index_column_id) AS included_columns
    FROM sys.index_columns ic
    INNER JOIN sys.columns c
        ON c.object_id = ic.object_id
       AND c.column_id = ic.column_id
    WHERE ic.object_id = i.object_id
      AND ic.index_id = i.index_id
      AND ic.is_included_column = 1
) include_cols
WHERE t.is_ms_shipped = 0
  AND i.index_id > 0
  AND i.is_hypothetical = 0
ORDER BY s.name, t.name, i.name;
