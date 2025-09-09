-- =====================================================
-- VIEWS AND STORED PROCEDURES FOR AUTOMATED REPORTING
-- File: 06_views_and_procedures.sql
-- =====================================================

-- ========================================
-- SECTION 1: BUSINESS INTELLIGENCE VIEWS
-- ========================================

-- View 1: Sales Overview Dashboard (with MoM & YoY growth)
DROP VIEW IF EXISTS sales_overview;
CREATE VIEW sales_overview AS
SELECT 
    DATE_FORMAT(o.OrderDate, '%Y-%m') as YearMonth,
    YEAR(o.OrderDate) as SalesYear,
    MONTH(o.OrderDate) as SalesMonth,
    COUNT(DISTINCT o.OrderID) as TotalOrders,
    COUNT(DISTINCT o.CustomerID) as UniqueCustomers,
    SUM(od.Sales) as Revenue,
    SUM(od.Profit) as Profit,
    AVG(od.Sales) as AvgOrderValue,
    SUM(od.Quantity) as TotalQuantity,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) as ProfitMargin,
    -- Growth metrics (requires MySQL 8+)
    LAG(SUM(od.Sales)) OVER (ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)) AS PrevMonthRevenue,
    ROUND(
        (SUM(od.Sales) - LAG(SUM(od.Sales)) OVER (ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)))
        / NULLIF(LAG(SUM(od.Sales)) OVER (ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)),0) * 100, 2
    ) AS MoM_GrowthPct,
    LAG(SUM(od.Sales), 12) OVER (ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)) AS PrevYearRevenue,
    ROUND(
        (SUM(od.Sales) - LAG(SUM(od.Sales),12) OVER (ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)))
        / NULLIF(LAG(SUM(od.Sales),12) OVER (ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)),0) * 100, 2
    ) AS YoY_GrowthPct
FROM orders o
JOIN order_details od ON o.OrderID = od.OrderID
GROUP BY DATE_FORMAT(o.OrderDate, '%Y-%m'), YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY SalesYear, SalesMonth;

-- View 2: Customer Performance View
DROP VIEW IF EXISTS customer_performance;
CREATE VIEW customer_performance AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Segment,
    c.Region,
    c.City,
    c.State,
    COUNT(DISTINCT o.OrderID) as TotalOrders,
    SUM(od.Sales) as TotalRevenue,
    SUM(od.Profit) as TotalProfit,
    AVG(od.Sales) as AvgOrderValue,
    MIN(o.OrderDate) as FirstOrderDate,
    MAX(o.OrderDate) as LastOrderDate,
    DATEDIFF(CURDATE(), MAX(o.OrderDate)) as DaysSinceLastOrder,
    DATEDIFF(MAX(o.OrderDate), MIN(o.OrderDate)) as CustomerLifespanDays,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) as ProfitMargin
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.CustomerName, c.Segment, c.Region, c.City, c.State;

-- View 3: Product Performance View
DROP VIEW IF EXISTS product_performance;
CREATE VIEW product_performance AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    p.SubCategory,
    COUNT(DISTINCT od.OrderID) as TimesOrdered,
    SUM(od.Quantity) as TotalQuantitySold,
    SUM(od.Sales) as TotalRevenue,
    SUM(od.Profit) as TotalProfit,
    AVG(od.Sales) as AvgSalePrice,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) as ProfitMargin,
    AVG(od.Discount) as AvgDiscountRate,
    MIN(DATE(o.OrderDate)) as FirstSaleDate,
    MAX(DATE(o.OrderDate)) as LastSaleDate
FROM products p
JOIN order_details od ON p.ProductID = od.ProductID
JOIN orders o ON od.OrderID = o.OrderID
GROUP BY p.ProductID, p.ProductName, p.Category, p.SubCategory;

-- View 4: Regional Performance View
DROP VIEW IF EXISTS regional_performance;
CREATE VIEW regional_performance AS
SELECT 
    c.Region,
    COUNT(DISTINCT c.CustomerID) as TotalCustomers,
    COUNT(DISTINCT o.OrderID) as TotalOrders,
    SUM(od.Sales) as TotalRevenue,
    SUM(od.Profit) as TotalProfit,
    AVG(od.Sales) as AvgOrderValue,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) as ProfitMargin,
    ROUND(SUM(od.Sales) / COUNT(DISTINCT c.CustomerID), 2) as RevenuePerCustomer,
    ROUND(COUNT(DISTINCT o.OrderID) / COUNT(DISTINCT c.CustomerID), 2) as OrdersPerCustomer
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
GROUP BY c.Region;

-- -----------------------------------------------------
-- Top Performer Views (with Ranking)
-- -----------------------------------------------------

-- View 5: Top Customers (with Revenue/Profit/Margin Ranks)
DROP VIEW IF EXISTS top_customers;
CREATE VIEW top_customers AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Segment,
    c.Region,
    ROUND(SUM(od.Sales), 2) as TotalRevenue,
    ROUND(SUM(od.Profit), 2) as TotalProfit,
    COUNT(DISTINCT o.OrderID) as TotalOrders,
    ROUND(SUM(od.Sales) / COUNT(DISTINCT o.OrderID), 2) as AvgOrderValue,
    MAX(o.OrderDate) as LastOrderDate,
    ROW_NUMBER() OVER (ORDER BY SUM(od.Sales) DESC) AS RevenueRank,
    ROW_NUMBER() OVER (ORDER BY SUM(od.Profit) DESC) AS ProfitRank,
    ROW_NUMBER() OVER (ORDER BY (SUM(od.Profit)/SUM(od.Sales)) DESC) AS MarginRank
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.CustomerName, c.Segment, c.Region
ORDER BY TotalRevenue DESC
LIMIT 50;

-- View 6: Top Products (with Ranking)
DROP VIEW IF EXISTS top_products;
CREATE VIEW top_products AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    p.SubCategory,
    SUM(od.Quantity) as TotalQuantitySold,
    ROUND(SUM(od.Sales), 2) as TotalRevenue,
    ROUND(SUM(od.Profit), 2) as TotalProfit,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) as ProfitMargin,
    ROW_NUMBER() OVER (ORDER BY SUM(od.Sales) DESC) AS RevenueRank,
    ROW_NUMBER() OVER (ORDER BY SUM(od.Profit) DESC) AS ProfitRank,
    ROW_NUMBER() OVER (ORDER BY (SUM(od.Profit)/SUM(od.Sales)) DESC) AS MarginRank
FROM products p
JOIN order_details od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category, p.SubCategory
ORDER BY TotalRevenue DESC
LIMIT 50;

-- View 7: Most Profitable Products
DROP VIEW IF EXISTS top_profitable_products;
CREATE VIEW top_profitable_products AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    p.SubCategory,
    ROUND(SUM(od.Profit), 2) as TotalProfit,
    ROUND(SUM(od.Sales), 2) as TotalRevenue,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) as ProfitMargin,
    SUM(od.Quantity) as UnitsSold
FROM products p
JOIN order_details od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category, p.SubCategory
ORDER BY TotalProfit DESC
LIMIT 50;

-- View 8: Loss-Making Products
DROP VIEW IF EXISTS loss_products;
CREATE VIEW loss_products AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    p.SubCategory,
    ROUND(SUM(od.Sales), 2) as TotalRevenue,
    ROUND(SUM(od.Profit), 2) as TotalProfit,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) as ProfitMargin,
    SUM(od.Quantity) as UnitsSold
FROM products p
JOIN order_details od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category, p.SubCategory
HAVING SUM(od.Profit) < 0
ORDER BY TotalProfit ASC
LIMIT 50;

-- View 9: Top Regions by Revenue
DROP VIEW IF EXISTS top_regions;
CREATE VIEW top_regions AS
SELECT 
    c.Region,
    ROUND(SUM(od.Sales), 2) as TotalRevenue,
    ROUND(SUM(od.Profit), 2) as TotalProfit,
    COUNT(DISTINCT c.CustomerID) as Customers,
    COUNT(DISTINCT o.OrderID) as Orders,
    ROUND(SUM(od.Sales) / COUNT(DISTINCT c.CustomerID), 2) as RevenuePerCustomer,
    ROUND(SUM(od.Sales) / COUNT(DISTINCT o.OrderID), 2) as RevenuePerOrder
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
GROUP BY c.Region
ORDER BY TotalRevenue DESC;


-- ========================================
-- SECTION 2: STORED PROCEDURES
-- ========================================

DELIMITER //
-- Stored Procedure 1: Daily Sales Summary Report
DROP PROCEDURE IF EXISTS GetDailySalesSummary //
CREATE PROCEDURE GetDailySalesSummary(IN report_date DATE)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    SELECT 
        'Daily Sales Summary Report' as ReportType,
        report_date as ReportDate;
        
    SELECT 
        COUNT(DISTINCT o.OrderID) as TotalOrders,
        COUNT(DISTINCT o.CustomerID) as UniqueCustomers,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Sales),0), 2)) as TotalRevenue,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Profit),0), 2)) as TotalProfit,
        CONCAT('$', FORMAT(COALESCE(AVG(od.Sales),0), 2)) as AvgOrderValue,
        COALESCE(SUM(od.Quantity),0) as TotalItemsSold,
        CASE WHEN COALESCE(SUM(od.Sales),0) = 0 THEN 0 ELSE ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) END as ProfitMargin
    FROM orders o
    JOIN order_details od ON o.OrderID = od.OrderID
    WHERE DATE(o.OrderDate) = report_date;
    
    -- Top 5 products for the day
    SELECT 'Top 5 Products Today' as Section;
    SELECT 
        p.ProductName,
        p.Category,
        SUM(od.Quantity) as QuantitySold,
        CONCAT('$', FORMAT(SUM(od.Sales), 2)) as Revenue
    FROM orders o
    JOIN order_details od ON o.OrderID = od.OrderID
    JOIN products p ON od.ProductID = p.ProductID
    WHERE DATE(o.OrderDate) = report_date
    GROUP BY p.ProductID, p.ProductName, p.Category
    ORDER BY SUM(od.Sales) DESC
    LIMIT 5;
END //
    
-- Stored Procedure 2: Customer Analysis Report
DROP PROCEDURE IF EXISTS GetCustomerAnalysisReport //
CREATE PROCEDURE GetCustomerAnalysisReport(IN customer_segment VARCHAR(20))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    SELECT 
        CONCAT('Customer Analysis Report - ', customer_segment, ' Segment') as ReportTitle;
    
    -- Summary metrics
    SELECT 
        customer_segment as Segment,
        COUNT(DISTINCT c.CustomerID) as TotalCustomers,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Sales),0), 2)) as TotalRevenue,
        CONCAT('$', FORMAT(COALESCE(AVG(od.Sales),0), 2)) as AvgOrderValue,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Sales) / NULLIF(COUNT(DISTINCT c.CustomerID),0),0), 2)) as RevenuePerCustomer
    FROM customers c
    JOIN orders o ON c.CustomerID = o.CustomerID
    JOIN order_details od ON o.OrderID = od.OrderID
    WHERE c.Segment = customer_segment
    GROUP BY c.Segment;
    
    -- Top customers in segment
    SELECT 'Top 10 Customers in Segment' as Section;
    SELECT 
        c.CustomerName,
        c.Region,
        COUNT(DISTINCT o.OrderID) as Orders,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Sales),0), 2)) as Revenue,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Profit),0), 2)) as Profit
    FROM customers c
    JOIN orders o ON c.CustomerID = o.CustomerID
    JOIN order_details od ON o.OrderID = od.OrderID
    WHERE c.Segment = customer_segment
    GROUP BY c.CustomerID, c.CustomerName, c.Region
    ORDER BY SUM(od.Sales) DESC
    LIMIT 10;
END //

-- Stored Procedure 3: Product Performance Report
DROP PROCEDURE IF EXISTS GetProductPerformanceReport //
CREATE PROCEDURE GetProductPerformanceReport(IN product_category VARCHAR(50))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    SELECT 
        CONCAT('Product Performance Report - ', product_category, ' Category') as ReportTitle;
    
    -- Category overview
    SELECT 
        p.Category,
        COUNT(DISTINCT p.ProductID) as TotalProducts,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Sales),0), 2)) as TotalRevenue,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Profit),0), 2)) as TotalProfit,
        CASE WHEN COALESCE(SUM(od.Sales),0)=0 THEN 0 ELSE ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) END as ProfitMargin
    FROM products p
    JOIN order_details od ON p.ProductID = od.ProductID
    WHERE p.Category = product_category
    GROUP BY p.Category;
    
    -- Top products in category
    SELECT 'Top 10 Products in Category' as Section;
    SELECT 
        p.ProductName,
        p.SubCategory,
        SUM(od.Quantity) as QuantitySold,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Sales),0), 2)) as Revenue,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Profit),0), 2)) as Profit,
        CASE WHEN COALESCE(SUM(od.Sales),0)=0 THEN 0 ELSE ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) END as ProfitMargin
    FROM products p
    JOIN order_details od ON p.ProductID = od.ProductID
    WHERE p.Category = product_category
    GROUP BY p.ProductID, p.ProductName, p.SubCategory
    ORDER BY SUM(od.Sales) DESC
    LIMIT 10;
    
    -- Worst performing products
    SELECT 'Bottom 5 Products in Category (Losses)' as Section;
    SELECT 
        p.ProductName,
        p.SubCategory,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Sales),0), 2)) as Revenue,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Profit),0), 2)) as Loss,
        CASE WHEN COALESCE(SUM(od.Sales),0)=0 THEN 0 ELSE ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) END as ProfitMargin
    FROM products p
    JOIN order_details od ON p.ProductID = od.ProductID
    WHERE p.Category = product_category
    GROUP BY p.ProductID, p.ProductName, p.SubCategory
    HAVING SUM(od.Profit) < 0
    ORDER BY SUM(od.Profit) ASC
    LIMIT 5;
END //

-- Stored Procedure 4: Monthly Executive Dashboard
DROP PROCEDURE IF EXISTS GetMonthlyExecutiveDashboard //
CREATE PROCEDURE GetMonthlyExecutiveDashboard(IN report_year INT, IN report_month INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    SELECT 
        CONCAT('Executive Dashboard - ', report_year, '-', LPAD(report_month, 2, '0')) as ReportTitle;
    
    -- Key metrics for the month
    SELECT 'Monthly Performance Summary' as Section;
    SELECT 
        COUNT(DISTINCT o.OrderID) as TotalOrders,
        COUNT(DISTINCT o.CustomerID) as UniqueCustomers,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Sales),0), 2)) as TotalRevenue,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Profit),0), 2)) as TotalProfit,
        CASE WHEN COALESCE(SUM(od.Sales),0)=0 THEN 0 ELSE ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) END as ProfitMargin,
        COALESCE(SUM(od.Quantity),0) as TotalItemsSold
    FROM orders o
    JOIN order_details od ON o.OrderID = od.OrderID
    WHERE YEAR(o.OrderDate) = report_year AND MONTH(o.OrderDate) = report_month;
    
    -- Regional performance
    SELECT 'Regional Performance' as Section;
    SELECT 
        c.Region,
        COUNT(DISTINCT o.OrderID) as Orders,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Sales),0), 2)) as Revenue,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Profit),0), 2)) as Profit
    FROM customers c
    JOIN orders o ON c.CustomerID = o.CustomerID
    JOIN order_details od ON o.OrderID = od.OrderID
    WHERE YEAR(o.OrderDate) = report_year AND MONTH(o.OrderDate) = report_month
    GROUP BY c.Region
    ORDER BY SUM(od.Sales) DESC;
    
    -- Category performance
    SELECT 'Category Performance' as Section;
    SELECT 
        p.Category,
        COUNT(DISTINCT o.OrderID) as Orders,
        CONCAT('$', FORMAT(COALESCE(SUM(od.Sales),0), 2)) as Revenue,
        CASE WHEN COALESCE(SUM(od.Sales),0)=0 THEN 0 ELSE ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) END as ProfitMargin
    FROM products p
    JOIN order_details od ON p.ProductID = od.ProductID
    JOIN orders o ON od.OrderID = o.OrderID
    WHERE YEAR(o.OrderDate) = report_year AND MONTH(o.OrderDate) = report_month
    GROUP BY p.Category
    ORDER BY SUM(od.Sales) DESC;
END //
DELIMITER ;

-- ========================================
-- SECTION 3: UTILITY PROCEDURES
-- ========================================

DELIMITER //
DROP PROCEDURE IF EXISTS RefreshAllViews //
CREATE PROCEDURE RefreshAllViews()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE view_name VARCHAR(64);
    DECLARE cur CURSOR FOR 
        SELECT TABLE_NAME 
        FROM information_schema.VIEWS 
        WHERE TABLE_SCHEMA = DATABASE();
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    SELECT 'Refreshing all views in database...' as Status;
    
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO view_name;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Views in MySQL are virtual, so this just validates they exist by running a lightweight count
        SET @sql = CONCAT('SELECT COUNT(*) as RecordCount FROM `', view_name, '` LIMIT 1');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    
    CLOSE cur;
    SELECT 'All views refreshed successfully!' as Status;
END //
DELIMITER ;

-- ========================================
-- SECTION 4: TESTING THE PROCEDURES
-- ========================================

-- Example calls:
CALL GetDailySalesSummary('2017-12-30');
CALL GetCustomerAnalysisReport('Consumer');
CALL GetProductPerformanceReport('Office Supplies');
CALL GetMonthlyExecutiveDashboard(2017, 12);

-- Show all created views in this database
SELECT 
    TABLE_NAME as ViewName,
    'View created successfully' as Status
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE();