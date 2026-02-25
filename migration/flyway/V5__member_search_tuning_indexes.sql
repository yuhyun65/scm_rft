/*
  SCM_RFT member search tuning indexes
  Target DB: SQL Server
*/

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_members_status_member_id' AND object_id = OBJECT_ID(N'dbo.members'))
BEGIN
    CREATE INDEX ix_members_status_member_id ON dbo.members (status, member_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_members_member_name_member_id' AND object_id = OBJECT_ID(N'dbo.members'))
BEGIN
    CREATE INDEX ix_members_member_name_member_id ON dbo.members (member_name, member_id);
END;
GO

