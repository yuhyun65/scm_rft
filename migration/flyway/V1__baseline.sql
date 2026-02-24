/*
  SCM_RFT Big-Bang baseline schema
  Target DB: SQL Server
*/

IF OBJECT_ID(N'dbo.members', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.members (
        member_id NVARCHAR(50) NOT NULL PRIMARY KEY,
        member_name NVARCHAR(200) NOT NULL,
        status NVARCHAR(20) NOT NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'dbo.auth_sessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.auth_sessions (
        session_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        member_id NVARCHAR(50) NOT NULL,
        access_token NVARCHAR(512) NOT NULL,
        expires_at DATETIME2 NOT NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'dbo.orders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.orders (
        order_no NVARCHAR(50) NOT NULL PRIMARY KEY,
        member_id NVARCHAR(50) NOT NULL,
        order_date DATE NOT NULL,
        status NVARCHAR(20) NOT NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'dbo.order_lots', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.order_lots (
        lot_no NVARCHAR(50) NOT NULL PRIMARY KEY,
        order_no NVARCHAR(50) NOT NULL,
        quantity DECIMAL(18, 3) NOT NULL,
        status NVARCHAR(20) NOT NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'dbo.upload_files', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.upload_files (
        file_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        domain_key NVARCHAR(100) NOT NULL,
        storage_path NVARCHAR(500) NOT NULL,
        original_name NVARCHAR(255) NOT NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_order_lots_order_no' AND object_id = OBJECT_ID(N'dbo.order_lots'))
BEGIN
    CREATE INDEX ix_order_lots_order_no ON dbo.order_lots (order_no);
END;
GO
