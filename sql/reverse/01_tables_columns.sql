SET NOCOUNT ON;

SELECT
    s.name AS table_schema,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS system_type,
    CASE
        WHEN ty.name IN ('varchar', 'char', 'binary', 'varbinary') AND c.max_length = -1
            THEN ty.name + '(max)'
        WHEN ty.name IN ('nvarchar', 'nchar') AND c.max_length = -1
            THEN ty.name + '(max)'
        WHEN ty.name IN ('nvarchar', 'nchar')
            THEN ty.name + '(' + CAST(c.max_length / 2 AS varchar(10)) + ')'
        WHEN ty.name IN ('varchar', 'char', 'binary', 'varbinary')
            THEN ty.name + '(' + CAST(c.max_length AS varchar(10)) + ')'
        WHEN ty.name IN ('decimal', 'numeric')
            THEN ty.name + '(' + CAST(c.precision AS varchar(10)) + ',' + CAST(c.scale AS varchar(10)) + ')'
        WHEN ty.name IN ('datetime2', 'time', 'datetimeoffset')
            THEN ty.name + '(' + CAST(c.scale AS varchar(10)) + ')'
        ELSE ty.name
    END AS data_type_display,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    dc.definition AS default_definition,
    c.collation_name
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
INNER JOIN sys.columns c
    ON c.object_id = t.object_id
INNER JOIN sys.types ty
    ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc
    ON dc.object_id = c.default_object_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;
