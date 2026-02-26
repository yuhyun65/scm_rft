/*
  SCM_RFT order-lot P0 query index tuning
  Target DB: SQL Server
*/

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_orders_status_order_no' AND object_id = OBJECT_ID(N'dbo.orders'))
BEGIN
    CREATE INDEX ix_orders_status_order_no
        ON dbo.orders (status, order_no);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_orders_member_status_order_no' AND object_id = OBJECT_ID(N'dbo.orders'))
BEGIN
    CREATE INDEX ix_orders_member_status_order_no
        ON dbo.orders (member_id, status, order_no);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_order_lots_order_no_lot_no' AND object_id = OBJECT_ID(N'dbo.order_lots'))
BEGIN
    CREATE INDEX ix_order_lots_order_no_lot_no
        ON dbo.order_lots (order_no, lot_no);
END;
GO
