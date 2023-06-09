-- This script enables the database for In-Memory OLTP if it is not already.
-- Then, it creates comparable disk-based and memory-optimized tables, as well as corresponding stored procedures
-- for sales order insertion.



/**********Start Of In-Memory OLTP Demo**********/

/* STEP 1: validate that In-Memory OLTP is supported */

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 1. validate that In-Memory OLTP is supported
IF SERVERPROPERTY(N'IsXTPSupported') = 0
BEGIN
    PRINT N'Error: In-Memory OLTP is not supported for this server edition or database pricing tier.';
END
IF DB_ID() < 5
BEGIN
    PRINT N'Error: In-Memory OLTP is not supported in system databases. Connect to a user database.';
END
ELSE
BEGIN
	BEGIN TRY
-- 2. add MEMORY_OPTIMIZED_DATA filegroup when not using Azure SQL DB
	IF SERVERPROPERTY('EngineEdition') != 5
	BEGIN
		DECLARE @SQLDataFolder nvarchar(max) = cast(SERVERPROPERTY('InstanceDefaultDataPath') as nvarchar(max))
		DECLARE @MODName nvarchar(max) = DB_NAME() + N'_mod';
		DECLARE @MemoryOptimizedFilegroupFolder nvarchar(max) = @SQLDataFolder + @MODName;

		DECLARE @SQL nvarchar(max) = N'';

		-- add filegroup
		IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE type = N'FX')
		BEGIN
			SET @SQL = N'
				ALTER DATABASE CURRENT
				ADD FILEGROUP ' + QUOTENAME(@MODName) + N' CONTAINS MEMORY_OPTIMIZED_DATA;';
			EXECUTE (@SQL);

			-- add container in the filegroup
			IF NOT EXISTS (SELECT * FROM sys.database_files WHERE data_space_id IN (SELECT data_space_id FROM sys.filegroups WHERE type = N'FX'))
			BEGIN
				SET @SQL = N'
				ALTER DATABASE CURRENT
				ADD FILE (name = N''' + @MODName + ''', filename = '''
						+ @MemoryOptimizedFilegroupFolder + N''')
				TO FILEGROUP ' + QUOTENAME(@MODName);
				EXECUTE (@SQL);
			END
		END;
	END

	-- 3. set compat level to 130 if it is lower
	IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()) < 130
		ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 130

	-- 4. enable MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT for the database
	ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;


    END TRY
    BEGIN CATCH
        PRINT N'Error enabling In-Memory OLTP';
		IF XACT_STATE() != 0
			ROLLBACK;
        THROW;
    END CATCH;
END;

/* STEP 2: Drop existing InMemory and OnDisk Objects */

DROP PROCEDURE IF EXISTS onDisk.InsertCustomerOrders
DROP PROCEDURE IF EXISTS InMemory.InsertCustomerOrders
DROP PROCEDURE IF EXISTS InMemory.InsertCustomerOrders_CCI

-- OnDisk Tables
DROP TABLE IF EXISTS OnDisk.OrderLines
DROP TABLE IF EXISTS OnDisk.Orders

-- InMemory Tables
DROP TABLE IF EXISTS InMemory.OrderLines
DROP TABLE IF EXISTS InMemory.Orders

-- InMemory Tables With Column Store Index
DROP TABLE IF EXISTS InMemory.OrderLines_CCI
DROP TABLE IF EXISTS InMemory.Orders_CCI

GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'OnDisk') EXEC ('CREATE SCHEMA OnDisk AUTHORIZATION dbo')
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'InMemory') EXEC ('CREATE SCHEMA InMemory AUTHORIZATION dbo')
GO

/* STEP 3: Create the disk based table and insert stored procedure */

CREATE TABLE [OnDisk].[OrderLines] (
    [OrderLineID] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[OrderID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[PickedQuantity] [int] NOT NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL DEFAULT(sysdatetime())
);
GO
CREATE TABLE [OnDisk].[Orders] (
	[OrderID] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL DEFAULT(sysdatetime())
);
GO

CREATE PROCEDURE [OnDisk].[InsertCustomerOrders]
@Orders Website.OrderList READONLY,
@OrderLines Website.OrderLineList READONLY,
@OrdersCreatedByPersonID int,
@SalespersonPersonID int
AS
BEGIN

	DECLARE @orderId INT

    INSERT OnDisk.Orders
			(CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate,
            ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered,
            PickingCompletedWhen, LastEditedBy, LastEditedWhen)
    SELECT	o.CustomerID, @SalespersonPersonID, NULL, o.ContactPersonID, NULL, SYSDATETIME(),
            o.ExpectedDeliveryDate, o.CustomerPurchaseOrderNumber, o.IsUndersupplyBackordered,
            NULL, @OrdersCreatedByPersonID, SYSDATETIME()
    FROM	@Orders AS o

	SELECT @orderId = SCOPE_IDENTITY()

    INSERT OnDisk.OrderLines
			(OrderID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice,
            TaxRate, PickedQuantity, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
    SELECT	@orderId, ol.StockItemID, ol.[Description], 0, ol.Quantity,
            rand()*1000, 15, 0, NULL, @OrdersCreatedByPersonID, SYSDATETIME()
    FROM @OrderLines AS ol

    RETURN 0;
END;
GO

/* STEP 4: Run the Workload Generator */

/* STEP 5: Create the in-memory and natively-compiled alternatives */

CREATE TABLE [InMemory].[OrderLines] (
    [OrderLineID] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
	[OrderID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[PickedQuantity] [int] NOT NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL DEFAULT(sysdatetime())
) WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_AND_DATA);
GO

CREATE TABLE [InMemory].[Orders] (
	[OrderID] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL DEFAULT(sysdatetime())
) WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_AND_DATA);
GO

CREATE PROCEDURE [InMemory].[InsertCustomerOrders]
@Orders Website.OrderList READONLY,
@OrderLines Website.OrderLineList READONLY,
@OrdersCreatedByPersonID int,
@SalespersonPersonID int
WITH NATIVE_COMPILATION, SCHEMABINDING
AS BEGIN ATOMIC WITH
(
 TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english'
)

	DECLARE @orderId INT

    INSERT InMemory.Orders
			(CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate,
            ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered,
            PickingCompletedWhen, LastEditedBy, LastEditedWhen)
    SELECT	o.CustomerID, @SalespersonPersonID, NULL, o.ContactPersonID, NULL, SYSDATETIME(),
            o.ExpectedDeliveryDate, o.CustomerPurchaseOrderNumber, o.IsUndersupplyBackordered,
            NULL, @OrdersCreatedByPersonID, SYSDATETIME()
    FROM	@Orders AS o

	SELECT @orderId = SCOPE_IDENTITY()

    INSERT InMemory.OrderLines
			(OrderID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice,
            TaxRate, PickedQuantity, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
    SELECT	@orderId, ol.StockItemID, ol.[Description], 0, ol.Quantity,
            rand()*1000, 15, 0, NULL, @OrdersCreatedByPersonID, SYSDATETIME()
    FROM @OrderLines AS ol

    RETURN 0;
END;
GO

/* STEP 6: Run the Workload Generator */

/**********End of In-Memory OLTP Demo**********/

/**********Start of Real Time Analytics Demo**********/

/* STEP 1: Create the in-memory and natively-compiled SP with a ColumnStore Index */
CREATE TABLE [InMemory].[OrderLines_CCI] (
    [OrderLineID] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
	[OrderID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[PickedQuantity] [int] NOT NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL DEFAULT(sysdatetime()),
	INDEX t_orderlines_cci CLUSTERED COLUMNSTORE
) WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_AND_DATA);
GO

CREATE TABLE [InMemory].[Orders_CCI] (
	[OrderID] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL DEFAULT(sysdatetime()),
	INDEX t_orders_cci CLUSTERED COLUMNSTORE
) WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_AND_DATA);
GO

CREATE PROCEDURE [InMemory].[InsertCustomerOrders_CCI]
@Orders Website.OrderList READONLY,
@OrderLines Website.OrderLineList READONLY,
@OrdersCreatedByPersonID int,
@SalespersonPersonID int
WITH NATIVE_COMPILATION, SCHEMABINDING
AS BEGIN ATOMIC WITH
(
 TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english'
)

	DECLARE @orderId INT

    INSERT InMemory.Orders_CCI
			(CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate,
            ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered,
            PickingCompletedWhen, LastEditedBy, LastEditedWhen)
    SELECT	o.CustomerID, @SalespersonPersonID, NULL, o.ContactPersonID, NULL, SYSDATETIME(),
            o.ExpectedDeliveryDate, o.CustomerPurchaseOrderNumber, o.IsUndersupplyBackordered,
            NULL, @OrdersCreatedByPersonID, SYSDATETIME()
    FROM	@Orders AS o

	SELECT @orderId = SCOPE_IDENTITY()

    INSERT InMemory.OrderLines_CCI
			(OrderID, StockItemID, [Description], PackageTypeID, Quantity, UnitPrice,
            TaxRate, PickedQuantity, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
    SELECT	@orderId, ol.StockItemID, ol.[Description], 0, ol.Quantity,
            rand()*1000, 15, 0, NULL, @OrdersCreatedByPersonID, SYSDATETIME()
    FROM @OrderLines AS ol

    RETURN 0;
END;
GO

/* STEP 2: Analytics Sample Query - No CCI */

/*
SELECT	o.SalespersonPersonID,
		o.CustomerId,
		SUM(ol.Quantity * ol.UnitPrice) AS TotalPrice,
		AVG(ol.Quantity * ol.UnitPrice) AS AvgPrice,
		MIN(o.LastEditedWhen) AS MinDate,
		MAX(o.LastEditedWhen) AS MaxDate
FROM	InMemory.Orders o
INNER JOIN
		InMemory.OrderLines ol ON o.OrderID = ol.OrderId
GROUP BY
		o.SalespersonPersonID,
		o.CustomerId
ORDER BY
		o.SalespersonPersonID,
		o.CustomerID


-- Analytics Sample Query - With CCI
SELECT	o.SalespersonPersonID,
		o.CustomerId,
		SUM(ol.Quantity * ol.UnitPrice) AS TotalPrice,
		AVG(ol.Quantity * ol.UnitPrice) AS AvgPrice,
		MIN(o.LastEditedWhen) AS MinDate,
		MAX(o.LastEditedWhen) AS MaxDate
FROM	InMemory.Orders_CCI o
INNER JOIN
		InMemory.OrderLines_CCI ol ON o.OrderID = ol.OrderId
GROUP BY
		o.SalespersonPersonID,
		o.CustomerId
ORDER BY
		o.SalespersonPersonID,
		o.CustomerID
*/
