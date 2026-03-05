SET NOCOUNT ON;

SELECT
    kc.type AS relation_type,
    kc.name AS constraint_name,
    ps.name AS parent_schema,
    pt.name AS parent_table,
    pcols.parent_columns,
    CAST(NULL AS sysname) AS referenced_schema,
    CAST(NULL AS sysname) AS referenced_table,
    CAST(NULL AS nvarchar(max)) AS referenced_columns,
    CAST(NULL AS nvarchar(60)) AS delete_action,
    CAST(NULL AS nvarchar(60)) AS update_action,
    CAST(0 AS bit) AS is_disabled,
    CAST(0 AS bit) AS is_not_trusted
FROM sys.key_constraints kc
INNER JOIN sys.tables pt
    ON pt.object_id = kc.parent_object_id
INNER JOIN sys.schemas ps
    ON ps.schema_id = pt.schema_id
OUTER APPLY (
    SELECT STRING_AGG(QUOTENAME(c.name), ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS parent_columns
    FROM sys.index_columns ic
    INNER JOIN sys.columns c
        ON c.object_id = ic.object_id
       AND c.column_id = ic.column_id
    WHERE ic.object_id = kc.parent_object_id
      AND ic.index_id = kc.unique_index_id
      AND ic.key_ordinal > 0
) pcols
WHERE pt.is_ms_shipped = 0
  AND kc.type IN ('PK', 'UQ')

UNION ALL

SELECT
    'FK' AS relation_type,
    fk.name AS constraint_name,
    ps.name AS parent_schema,
    pt.name AS parent_table,
    pcols.parent_columns,
    rs.name AS referenced_schema,
    rt.name AS referenced_table,
    rcols.referenced_columns,
    fk.delete_referential_action_desc AS delete_action,
    fk.update_referential_action_desc AS update_action,
    fk.is_disabled,
    fk.is_not_trusted
FROM sys.foreign_keys fk
INNER JOIN sys.tables pt
    ON pt.object_id = fk.parent_object_id
INNER JOIN sys.schemas ps
    ON ps.schema_id = pt.schema_id
INNER JOIN sys.tables rt
    ON rt.object_id = fk.referenced_object_id
INNER JOIN sys.schemas rs
    ON rs.schema_id = rt.schema_id
OUTER APPLY (
    SELECT STRING_AGG(QUOTENAME(pc.name), ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS parent_columns
    FROM sys.foreign_key_columns fkc
    INNER JOIN sys.columns pc
        ON pc.object_id = fkc.parent_object_id
       AND pc.column_id = fkc.parent_column_id
    WHERE fkc.constraint_object_id = fk.object_id
) pcols
OUTER APPLY (
    SELECT STRING_AGG(QUOTENAME(rc.name), ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS referenced_columns
    FROM sys.foreign_key_columns fkc
    INNER JOIN sys.columns rc
        ON rc.object_id = fkc.referenced_object_id
       AND rc.column_id = fkc.referenced_column_id
    WHERE fkc.constraint_object_id = fk.object_id
) rcols
WHERE pt.is_ms_shipped = 0
  AND rt.is_ms_shipped = 0

ORDER BY relation_type, parent_schema, parent_table, constraint_name;
