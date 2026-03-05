SET NOCOUNT ON;

SELECT
    ps.name AS procedure_schema,
    p.name AS procedure_name,
    COALESCE(rs.name, sed.referenced_schema_name) AS referenced_schema,
    COALESCE(ro.name, sed.referenced_entity_name) AS referenced_entity,
    ro.type_desc AS referenced_type_desc,
    sed.referenced_class_desc,
    sed.is_ambiguous,
    sed.is_caller_dependent
FROM sys.procedures p
INNER JOIN sys.schemas ps
    ON ps.schema_id = p.schema_id
LEFT JOIN sys.sql_expression_dependencies sed
    ON sed.referencing_id = p.object_id
LEFT JOIN sys.objects ro
    ON ro.object_id = sed.referenced_id
LEFT JOIN sys.schemas rs
    ON rs.schema_id = ro.schema_id
WHERE p.is_ms_shipped = 0
  AND (
      sed.referenced_id IS NOT NULL
      OR sed.referenced_entity_name IS NOT NULL
  )
ORDER BY
    procedure_schema,
    procedure_name,
    referenced_schema,
    referenced_entity;
