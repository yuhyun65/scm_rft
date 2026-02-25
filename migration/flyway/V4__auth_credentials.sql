/*
  SCM_RFT auth credential schema
  Target DB: SQL Server
*/

IF OBJECT_ID(N'dbo.auth_credentials', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.auth_credentials (
        login_id NVARCHAR(50) NOT NULL,
        member_id NVARCHAR(50) NOT NULL,
        password_hash NVARCHAR(255) NOT NULL,
        password_algo NVARCHAR(20) NOT NULL DEFAULT N'BCRYPT',
        failed_count INT NOT NULL DEFAULT 0,
        locked_until DATETIME2 NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_auth_credentials PRIMARY KEY (login_id)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'ck_auth_credentials_algo')
BEGIN
    ALTER TABLE dbo.auth_credentials
    ADD CONSTRAINT ck_auth_credentials_algo CHECK (password_algo IN (N'BCRYPT'));
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'fk_auth_credentials_member')
BEGIN
    ALTER TABLE dbo.auth_credentials
    ADD CONSTRAINT fk_auth_credentials_member
    FOREIGN KEY (member_id) REFERENCES dbo.members(member_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ux_auth_credentials_member_id' AND object_id = OBJECT_ID(N'dbo.auth_credentials'))
BEGIN
    CREATE UNIQUE INDEX ux_auth_credentials_member_id ON dbo.auth_credentials (member_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_auth_credentials_locked_until' AND object_id = OBJECT_ID(N'dbo.auth_credentials'))
BEGIN
    CREATE INDEX ix_auth_credentials_locked_until ON dbo.auth_credentials (locked_until);
END;
GO

