/*
  SCM_RFT auth/member lookup indexes
  Target DB: SQL Server
*/

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'fk_auth_sessions_member')
BEGIN
    ALTER TABLE dbo.auth_sessions
    ADD CONSTRAINT fk_auth_sessions_member
    FOREIGN KEY (member_id) REFERENCES dbo.members(member_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ux_auth_sessions_access_token' AND object_id = OBJECT_ID(N'dbo.auth_sessions'))
BEGIN
    CREATE UNIQUE INDEX ux_auth_sessions_access_token ON dbo.auth_sessions (access_token);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_auth_sessions_expires_at' AND object_id = OBJECT_ID(N'dbo.auth_sessions'))
BEGIN
    CREATE INDEX ix_auth_sessions_expires_at ON dbo.auth_sessions (expires_at);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_members_status_member_name' AND object_id = OBJECT_ID(N'dbo.members'))
BEGIN
    CREATE INDEX ix_members_status_member_name ON dbo.members (status, member_name);
END;
GO

