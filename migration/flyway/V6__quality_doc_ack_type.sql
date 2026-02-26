/*
  SCM_RFT quality-doc ack idempotency support
  Target DB: SQL Server
*/

IF OBJECT_ID(N'dbo.quality_document_acks', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.quality_document_acks', N'ack_type') IS NULL
    BEGIN
        ALTER TABLE dbo.quality_document_acks
        ADD ack_type NVARCHAR(20) NULL;
    END;
END;
GO

IF OBJECT_ID(N'dbo.quality_document_acks', N'U') IS NOT NULL
BEGIN
    UPDATE dbo.quality_document_acks
    SET ack_type = N'READ'
    WHERE ack_type IS NULL;
END;
GO

IF OBJECT_ID(N'dbo.quality_document_acks', N'U') IS NOT NULL
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.quality_document_acks')
          AND name = N'ack_type'
          AND is_nullable = 1
    )
    BEGIN
        ALTER TABLE dbo.quality_document_acks
        ALTER COLUMN ack_type NVARCHAR(20) NOT NULL;
    END;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'ck_quality_document_acks_ack_type')
BEGIN
    ALTER TABLE dbo.quality_document_acks
    ADD CONSTRAINT ck_quality_document_acks_ack_type
    CHECK (ack_type IN (N'READ', N'CONFIRMED'));
END;
GO
