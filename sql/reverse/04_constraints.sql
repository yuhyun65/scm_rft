SET NOCOUNT ON;

SELECT
    'DEFAULT' AS constraint_type,
    dc.name AS constraint_name,
    s.name AS table_schema,
    t.name AS table_name,
    c.name AS column_name,
    dc.definition,
    CAST(0 AS bit) AS is_disabled,
    CAST(0 AS bit) AS is_not_trusted
FROM sys.default_constraints dc
INNER JOIN sys.tables t
    ON t.object_id = dc.parent_object_id
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
INNER JOIN sys.columns c
    ON c.object_id = dc.parent_object_id
   AND c.column_id = dc.parent_column_id
WHERE t.is_ms_shipped = 0

UNION ALL

SELECT
    'CHECK' AS constraint_type,
    cc.name AS constraint_name,
    s.name AS table_schema,
    t.name AS table_name,
    CASE
        WHEN cc.parent_column_id > 0 THEN c.name
        ELSE NULL
    END AS column_name,
    cc.definition,
    cc.is_disabled,
    cc.is_not_trusted
FROM sys.check_constraints cc
INNER JOIN sys.tables t
    ON t.object_id = cc.parent_object_id
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.columns c
    ON c.object_id = cc.parent_object_id
   AND c.column_id = cc.parent_column_id
WHERE t.is_ms_shipped = 0

ORDER BY constraint_type, table_schema, table_name, constraint_name;
