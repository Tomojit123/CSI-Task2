use AdventureWorks2022
go
IF OBJECT_ID('InsertOrderDetails', 'P') IS NOT NULL
    DROP PROCEDURE InsertOrderDetails;
GO

CREATE PROCEDURE InsertOrderDetails 
(
    @OrderID INT,
    @ProductID INT,
    @UnitPrice DECIMAL(19, 4) = NULL,
    @Quantity INT,
    @Discount DECIMAL(4, 2) = 0
)
AS
BEGIN
    DECLARE @v_UnitPrice DECIMAL(19, 4);
    DECLARE @v_UnitsInStock INT;
    DECLARE @v_ReorderLevel INT;
    DECLARE @v_RowCount INT;

    -- Get product details
    SELECT @v_UnitPrice = UnitPrice, @v_UnitsInStock = UnitsInStock, @v_ReorderLevel = ReorderLevel
    FROM Product
    WHERE ProductID = @ProductID;

    -- Use default UnitPrice if not provided
    IF @UnitPrice IS NULL
    BEGIN
        SET @UnitPrice = @v_UnitPrice;
    END

    -- Check inventory
    IF @v_UnitsInStock < @Quantity
    BEGIN
        PRINT 'Not enough inventory to fulfill the order.';
        RETURN;
    END

    -- Insert into OrderDetails
    INSERT INTO OrderDetails (OrderID, ProductID, UnitPrice, Quantity, Discount)
    VALUES (@OrderID, @ProductID, @UnitPrice, @Quantity, @Discount);

    SET @v_RowCount = @@ROWCOUNT;

    -- Check if insertion was successful
    IF @v_RowCount = 0
    BEGIN
        PRINT 'Failed to place the order. Please try again.';
        RETURN;
    END

    -- Update inventory
    UPDATE Product
    SET UnitsInStock = UnitsInStock - @Quantity
    WHERE ProductID = @ProductID;

    -- Check reorder level
    IF (@v_UnitsInStock - @Quantity) < @v_ReorderLevel
    BEGIN
        PRINT 'Warning: Quantity in stock has dropped below reorder level!';
    END
END
GO

--update order details

IF OBJECT_ID('UpdateOrderDetails', 'P') IS NOT NULL
    DROP PROCEDURE UpdateOrderDetails;
GO

CREATE PROCEDURE UpdateOrderDetails 
(
    @OrderID INT,
    @ProductID INT,
    @UnitPrice DECIMAL(19, 4) = NULL,
    @Quantity INT = NULL,
    @Discount DECIMAL(4, 2) = NULL
)
AS
BEGIN
    DECLARE @OriginalUnitPrice DECIMAL(19, 4);
    DECLARE @OriginalQuantity INT;
    DECLARE @OriginalDiscount DECIMAL(4, 2);
    DECLARE @OriginalUnitsInStock INT;
    DECLARE @NewUnitsInStock INT;

    -- Get original values from OrderDetails
    SELECT @OriginalUnitPrice = UnitPrice, @OriginalQuantity = Quantity, @OriginalDiscount = Discount
    FROM OrderDetails
    WHERE OrderID = @OrderID AND ProductID = @ProductID;

    -- Get original UnitsInStock from Product
    SELECT @OriginalUnitsInStock = UnitsInStock
    FROM Product
    WHERE ProductID = @ProductID;

    -- Update UnitsInStock to add back the original quantity before updating
    SET @NewUnitsInStock = @OriginalUnitsInStock + @OriginalQuantity;

    -- Update OrderDetails
    UPDATE OrderDetails
    SET 
        UnitPrice = ISNULL(@UnitPrice, @OriginalUnitPrice),
        Quantity = ISNULL(@Quantity, @OriginalQuantity),
        Discount = ISNULL(@Discount, @OriginalDiscount)
    WHERE OrderID = @OrderID AND ProductID = @ProductID;
	 
    -- Calculate new UnitsInStock after update
    SET @NewUnitsInStock = @NewUnitsInStock - ISNULL(@Quantity, @OriginalQuantity);

    -- Check inventory
    IF @NewUnitsInStock < 0
    BEGIN
        PRINT 'Not enough inventory to fulfill the order.';
        -- Revert OrderDetails update
        UPDATE OrderDetails
        SET 
            UnitPrice = @OriginalUnitPrice,
            Quantity = @OriginalQuantity,
            Discount = @OriginalDiscount
        WHERE OrderID = @OrderID AND ProductID = @ProductID;
        RETURN;
    END

    -- Apply the new UnitsInStock value to Product
    UPDATE Product
    SET UnitsInStock = @NewUnitsInStock
    WHERE ProductID = @ProductID;

    -- Check reorder level
    DECLARE @ReorderLevel INT;
    SELECT @ReorderLevel = ReorderLevel
    FROM Product
    WHERE ProductID = @ProductID;

    IF @NewUnitsInStock < @ReorderLevel
    BEGIN
        PRINT 'Warning: Quantity in stock has dropped below reorder level!';
    END
END
GO
--procedure to get order details

IF OBJECT_ID('GetOrderDetails', 'P') IS NOT NULL
    DROP PROCEDURE GetOrderDetails;
GO

CREATE PROCEDURE GetOrderDetails
(
    @OrderID INT
)
AS
BEGIN
    -- Check if there are any records for the given OrderID
    IF NOT EXISTS (SELECT 1 FROM OrderDetails WHERE OrderID = @OrderID)
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist';
        RETURN 1;
    END

    -- Select records for the given OrderID
    SELECT OrderID, ProductID, UnitPrice, Quantity, Discount
    FROM OrderDetails
    WHERE OrderID = @OrderID;
END
GO
--delecte order details

IF OBJECT_ID('DeleteOrderDetails', 'P') IS NOT NULL
    DROP PROCEDURE DeleteOrderDetails;
GO

CREATE PROCEDURE DeleteOrderDetails
(
    @OrderID INT,
    @ProductID INT
)
AS
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM OrderDetails WHERE OrderID = @OrderID)
    BEGIN
        PRINT 'Error: The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist.';
        RETURN -1;
    END

    
    IF NOT EXISTS (SELECT 1 FROM OrderDetails WHERE OrderID = @OrderID AND ProductID = @ProductID)
    BEGIN
        PRINT 'Error: The ProductID ' + CAST(@ProductID AS VARCHAR) + ' does not exist for OrderID ' + CAST(@OrderID AS VARCHAR) + '.';
        RETURN -1;
    END

    -- Delete the record from OrderDetails table
    DELETE FROM OrderDetails
    WHERE OrderID = @OrderID AND ProductID = @ProductID;

    PRINT 'Success: The record for OrderID ' + CAST(@OrderID AS VARCHAR) + ' and ProductID ' + CAST(@ProductID AS VARCHAR) + ' has been deleted.';
END
GO





