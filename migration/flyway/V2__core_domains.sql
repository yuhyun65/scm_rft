/*
  SCM_RFT core domains schema (P0)
  Target DB: SQL Server
*/

IF OBJECT_ID(N'dbo.board_posts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.board_posts (
        post_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
        category_code NVARCHAR(30) NOT NULL,
        title NVARCHAR(200) NOT NULL,
        content NVARCHAR(MAX) NULL,
        writer_member_id NVARCHAR(50) NULL,
        is_notice BIT NOT NULL DEFAULT 0,
        status NVARCHAR(20) NOT NULL DEFAULT N'ACTIVE',
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'dbo.board_post_attachments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.board_post_attachments (
        post_id UNIQUEIDENTIFIER NOT NULL,
        file_id UNIQUEIDENTIFIER NOT NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_board_post_attachments PRIMARY KEY (post_id, file_id)
    );
END;
GO

IF OBJECT_ID(N'dbo.quality_documents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.quality_documents (
        document_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
        title NVARCHAR(200) NOT NULL,
        document_type NVARCHAR(30) NOT NULL,
        issued_at DATETIME2 NOT NULL,
        publisher_member_id NVARCHAR(50) NULL,
        status NVARCHAR(20) NOT NULL DEFAULT N'ISSUED',
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'dbo.quality_document_acks', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.quality_document_acks (
        document_id UNIQUEIDENTIFIER NOT NULL,
        member_id NVARCHAR(50) NOT NULL,
        ack_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_quality_document_acks PRIMARY KEY (document_id, member_id)
    );
END;
GO

IF OBJECT_ID(N'dbo.inventory_balances', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.inventory_balances (
        item_code NVARCHAR(100) NOT NULL,
        warehouse_code NVARCHAR(50) NOT NULL,
        quantity DECIMAL(18, 3) NOT NULL DEFAULT 0,
        updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT pk_inventory_balances PRIMARY KEY (item_code, warehouse_code)
    );
END;
GO

IF OBJECT_ID(N'dbo.inventory_movements', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.inventory_movements (
        movement_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
        item_code NVARCHAR(100) NOT NULL,
        warehouse_code NVARCHAR(50) NOT NULL,
        movement_type NVARCHAR(20) NOT NULL,
        quantity DECIMAL(18, 3) NOT NULL,
        reference_no NVARCHAR(100) NULL,
        moved_at DATETIME2 NOT NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'dbo.report_jobs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.report_jobs (
        job_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
        report_type NVARCHAR(50) NOT NULL,
        requested_by_member_id NVARCHAR(50) NULL,
        status NVARCHAR(20) NOT NULL DEFAULT N'QUEUED',
        requested_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        completed_at DATETIME2 NULL,
        output_file_id UNIQUEIDENTIFIER NULL,
        error_message NVARCHAR(1000) NULL
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'ck_board_posts_status')
BEGIN
    ALTER TABLE dbo.board_posts
    ADD CONSTRAINT ck_board_posts_status CHECK (status IN (N'ACTIVE', N'DELETED', N'HIDDEN'));
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'ck_quality_documents_status')
BEGIN
    ALTER TABLE dbo.quality_documents
    ADD CONSTRAINT ck_quality_documents_status CHECK (status IN (N'ISSUED', N'RECEIVED', N'ARCHIVED'));
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'ck_inventory_movements_type')
BEGIN
    ALTER TABLE dbo.inventory_movements
    ADD CONSTRAINT ck_inventory_movements_type CHECK (movement_type IN (N'IN', N'OUT', N'ADJUST'));
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'ck_report_jobs_status')
BEGIN
    ALTER TABLE dbo.report_jobs
    ADD CONSTRAINT ck_report_jobs_status CHECK (status IN (N'QUEUED', N'RUNNING', N'COMPLETED', N'FAILED'));
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'fk_board_posts_writer_member')
BEGIN
    ALTER TABLE dbo.board_posts
    ADD CONSTRAINT fk_board_posts_writer_member
    FOREIGN KEY (writer_member_id) REFERENCES dbo.members(member_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'fk_board_post_attachments_post')
BEGIN
    ALTER TABLE dbo.board_post_attachments
    ADD CONSTRAINT fk_board_post_attachments_post
    FOREIGN KEY (post_id) REFERENCES dbo.board_posts(post_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'fk_board_post_attachments_file')
BEGIN
    ALTER TABLE dbo.board_post_attachments
    ADD CONSTRAINT fk_board_post_attachments_file
    FOREIGN KEY (file_id) REFERENCES dbo.upload_files(file_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'fk_quality_documents_publisher')
BEGIN
    ALTER TABLE dbo.quality_documents
    ADD CONSTRAINT fk_quality_documents_publisher
    FOREIGN KEY (publisher_member_id) REFERENCES dbo.members(member_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'fk_quality_document_acks_document')
BEGIN
    ALTER TABLE dbo.quality_document_acks
    ADD CONSTRAINT fk_quality_document_acks_document
    FOREIGN KEY (document_id) REFERENCES dbo.quality_documents(document_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'fk_quality_document_acks_member')
BEGIN
    ALTER TABLE dbo.quality_document_acks
    ADD CONSTRAINT fk_quality_document_acks_member
    FOREIGN KEY (member_id) REFERENCES dbo.members(member_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'fk_report_jobs_requested_by_member')
BEGIN
    ALTER TABLE dbo.report_jobs
    ADD CONSTRAINT fk_report_jobs_requested_by_member
    FOREIGN KEY (requested_by_member_id) REFERENCES dbo.members(member_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'fk_report_jobs_output_file')
BEGIN
    ALTER TABLE dbo.report_jobs
    ADD CONSTRAINT fk_report_jobs_output_file
    FOREIGN KEY (output_file_id) REFERENCES dbo.upload_files(file_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_board_posts_category_created_at' AND object_id = OBJECT_ID(N'dbo.board_posts'))
BEGIN
    CREATE INDEX ix_board_posts_category_created_at ON dbo.board_posts (category_code, created_at);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_board_post_attachments_file_id' AND object_id = OBJECT_ID(N'dbo.board_post_attachments'))
BEGIN
    CREATE INDEX ix_board_post_attachments_file_id ON dbo.board_post_attachments (file_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_quality_documents_issued_at' AND object_id = OBJECT_ID(N'dbo.quality_documents'))
BEGIN
    CREATE INDEX ix_quality_documents_issued_at ON dbo.quality_documents (issued_at);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_quality_document_acks_member_ack_at' AND object_id = OBJECT_ID(N'dbo.quality_document_acks'))
BEGIN
    CREATE INDEX ix_quality_document_acks_member_ack_at ON dbo.quality_document_acks (member_id, ack_at);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_inventory_movements_item_wh_moved_at' AND object_id = OBJECT_ID(N'dbo.inventory_movements'))
BEGIN
    CREATE INDEX ix_inventory_movements_item_wh_moved_at ON dbo.inventory_movements (item_code, warehouse_code, moved_at);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_report_jobs_status_requested_at' AND object_id = OBJECT_ID(N'dbo.report_jobs'))
BEGIN
    CREATE INDEX ix_report_jobs_status_requested_at ON dbo.report_jobs (status, requested_at);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_report_jobs_output_file_id' AND object_id = OBJECT_ID(N'dbo.report_jobs'))
BEGIN
    CREATE INDEX ix_report_jobs_output_file_id ON dbo.report_jobs (output_file_id);
END;
GO
