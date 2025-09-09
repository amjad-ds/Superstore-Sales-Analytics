-- =====================================================
-- SUPERSTORE ANALYTICS - DATA IMPORT & NORMALIZATION
-- File: 02_data_import.sql
-- =====================================================

-- Step 1: Load CSV data into staging table using MySQL Workbench's Table Data Import Wizard
-- MANUAL STEP: Right-click on staging_superstore table → "Table Data Import Wizard" 
-- → Browse to 'C:/Users/USER/Downloads/archive/Sample - Superstore.csv'
-- → Follow the import wizard (it will auto-map columns)

-- Step 2: After CSV import, normalize data into proper tables

-- Clean and insert unique customers
INSERT INTO customers (CustomerID, CustomerName, Segment, Country, City, State, PostalCode, Region)
SELECT
    TRIM(s.CustomerID) AS CustomerID,
    MIN(TRIM(s.CustomerName)) AS CustomerName,  -- pick one value
    MIN(TRIM(s.Segment)) AS Segment,
    MIN(TRIM(s.Country)) AS Country,
    MIN(TRIM(s.City)) AS City,
    MIN(TRIM(s.State)) AS State,
    MIN(TRIM(IFNULL(s.PostalCode, ''))) AS PostalCode,
    MIN(TRIM(s.Region)) AS Region
FROM staging_superstore s
WHERE s.CustomerID IS NOT NULL
  AND TRIM(s.CustomerID) != ''
  AND TRIM(s.CustomerID) != 'Customer ID'
  AND NOT EXISTS (
      SELECT 1 FROM customers c
      WHERE c.CustomerID = TRIM(s.CustomerID)
  )
GROUP BY TRIM(s.CustomerID);

-- Clean and insert unique products  
INSERT INTO products (ProductID, Category, SubCategory, ProductName)
SELECT
    TRIM(s.ProductID) AS ProductID,
    MIN(TRIM(s.Category)) AS Category,       -- pick one consistent value
    MIN(TRIM(s.SubCategory)) AS SubCategory,
    MIN(TRIM(s.ProductName)) AS ProductName
FROM staging_superstore s
WHERE s.ProductID IS NOT NULL
  AND TRIM(s.ProductID) != ''
  AND TRIM(s.ProductID) != 'Product ID'
  AND NOT EXISTS (
      SELECT 1 FROM products p
      WHERE p.ProductID = TRIM(s.ProductID)
  )
GROUP BY TRIM(s.ProductID);

-- Clean and insert unique orders (handling proper date conversion)
INSERT IGNORE INTO orders (OrderID, CustomerID, OrderDate, ShipDate, ShipMode)
SELECT DISTINCT 
    TRIM(OrderID) as OrderID,
    TRIM(CustomerID) as CustomerID,
    CASE 
        WHEN OrderDate REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' 
        THEN STR_TO_DATE(OrderDate, '%m/%d/%Y')
        WHEN OrderDate REGEXP '^[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}$' 
        THEN STR_TO_DATE(OrderDate, '%m-%d-%Y')
        ELSE NULL
    END as OrderDate,
    CASE 
        WHEN ShipDate REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' 
        THEN STR_TO_DATE(ShipDate, '%m/%d/%Y')
        WHEN ShipDate REGEXP '^[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}$' 
        THEN STR_TO_DATE(ShipDate, '%m-%d-%Y')  
        ELSE NULL
    END as ShipDate,
    TRIM(ShipMode) as ShipMode
FROM staging_superstore 
WHERE OrderID IS NOT NULL 
AND OrderID != ''
AND OrderID != 'Order ID'
AND OrderDate IS NOT NULL;

-- Clean and insert order details with better error handling
INSERT INTO order_details (RowID, OrderID, ProductID, Sales, Quantity, Discount, Profit)
SELECT 
    CAST(TRIM(RowID) AS SIGNED) AS RowID,
    TRIM(OrderID) AS OrderID,
    TRIM(ProductID) AS ProductID,

    -- Sales cleaning
    CASE 
        WHEN Sales REGEXP '^[0-9]+\.?[0-9]*$' 
             AND CAST(Sales AS DECIMAL(20,6)) <= 999999999.999999
        THEN CAST(Sales AS DECIMAL(15,6))
        ELSE 0 
    END AS Sales,

    -- Quantity cleaning
    CASE 
        WHEN Quantity REGEXP '^[0-9]+$' 
             AND CAST(Quantity AS SIGNED) <= 2147483647
        THEN CAST(Quantity AS SIGNED)
        ELSE 1 
    END AS Quantity,

    -- Discount normalization (force 0–1 range to satisfy CHECK constraint)
    CASE 
        WHEN Discount REGEXP '^[0-9]*\.?[0-9]+$' 
        THEN 
            CAST(
                CASE 
                    WHEN CAST(Discount AS DECIMAL(10,6)) > 1 
                         AND CAST(Discount AS DECIMAL(10,6)) <= 100 
                    THEN CAST(Discount AS DECIMAL(10,6)) / 100   -- convert percentage → fraction
                    WHEN CAST(Discount AS DECIMAL(10,6)) > 100 
                    THEN 1                                       -- cap at 100%
                    ELSE CAST(Discount AS DECIMAL(10,6))         -- already a fraction
                END 
            AS DECIMAL(5,4))
        ELSE 0
    END AS Discount,

    -- Profit cleaning
    CASE 
        WHEN Profit REGEXP '^-?[0-9]+\.?[0-9]*$' 
             AND ABS(CAST(Profit AS DECIMAL(20,6))) <= 999999999.999999
        THEN CAST(Profit AS DECIMAL(15,6))
        ELSE 0 
    END AS Profit

FROM staging_superstore 
WHERE OrderID IS NOT NULL 
  AND OrderID != ''
  AND OrderID != 'Order ID'
  AND RowID REGEXP '^[0-9]+$'
  AND EXISTS (SELECT 1 FROM orders o WHERE o.OrderID = TRIM(staging_superstore.OrderID))
  AND EXISTS (SELECT 1 FROM products p WHERE p.ProductID = TRIM(staging_superstore.ProductID));

-- Verification queries
SELECT 'Customers' as TableName, COUNT(*) as RecordCount, 'Unique customer records' as Notes FROM customers
UNION ALL
SELECT 'Products', COUNT(*), 'Unique product records' FROM products  
UNION ALL
SELECT 'Orders', COUNT(*), 'Unique order records' FROM orders
UNION ALL
SELECT 'OrderDetails', COUNT(*), 'Line items of orders' FROM order_details
UNION ALL
SELECT 'StagingSuperstore', COUNT(*), 'Raw staging data' FROM staging_superstore;

-- Final verification and data quality check
SELECT 
    'Sales Analysis' as Metric,
    COUNT(*) as TotalRecords,
    CONCAT('$', FORMAT(MIN(Sales), 2)) as Min,
    CONCAT('$', FORMAT(AVG(Sales), 2)) as Avg,
    CONCAT('$', FORMAT(MAX(Sales), 2)) as Max,
    COUNT(CASE WHEN Sales = 0 THEN 1 END) as ZeroCount
FROM order_details

UNION ALL

SELECT 
    'Profit Analysis',
    COUNT(*),
    CONCAT('$', FORMAT(MIN(Profit), 2)),
    CONCAT('$', FORMAT(AVG(Profit), 2)),
    CONCAT('$', FORMAT(MAX(Profit), 2)),
    COUNT(CASE WHEN Profit < 0 THEN 1 END)
FROM order_details;
SHOW CREATE TABLE order_details;

-- Check date range
SELECT 
    'Date Range' as Info,
    MIN(OrderDate) as StartDate,
    MAX(OrderDate) as EndDate,
    DATEDIFF(MAX(OrderDate), MIN(OrderDate)) as TotalDays,
    COUNT(DISTINCT YEAR(OrderDate)) as Years
FROM orders;