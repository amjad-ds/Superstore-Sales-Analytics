-- =====================================================
-- TOP PERFORMERS ANALYSIS
-- File: 05_top_performers_analysis.sql
-- =====================================================

-- Step 1: Top 10 Customers by Revenue
SELECT 
    c.CustomerName,
    c.Segment,
    c.Region,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    SUM(od.Quantity) AS TotalItems,
    ROUND(SUM(od.Sales), 2) AS TotalRevenue,
    ROUND(SUM(od.Profit), 2) AS TotalProfit,
    ROUND(SUM(od.Sales) / COUNT(DISTINCT o.OrderID), 2) AS AvgOrderValue,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) AS ProfitMargin,
    MAX(o.OrderDate) AS LastOrderDate,
    DATEDIFF(CURDATE(), MAX(o.OrderDate)) AS DaysSinceLastOrder
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.CustomerName, c.Segment, c.Region
ORDER BY SUM(od.Sales) DESC
LIMIT 10;

-- Step 2: Top 10 Products by Revenue
SELECT 
    p.ProductName,
    p.Category,
    p.SubCategory,
    COUNT(DISTINCT od.OrderID) AS TimesOrdered,
    SUM(od.Quantity) AS TotalQuantitySold,
    ROUND(SUM(od.Sales), 2) AS TotalRevenue,
    ROUND(SUM(od.Profit), 2) AS TotalProfit,
    ROUND(SUM(od.Sales) / SUM(od.Quantity), 2) AS AvgSalePrice, -- corrected
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) AS ProfitMargin,
    ROUND(AVG(od.Discount) * 100, 2) AS AvgDiscountPercent
FROM products p
JOIN order_details od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category, p.SubCategory
ORDER BY SUM(od.Sales) DESC
LIMIT 10;

-- Step 3: Top 10 Products by Profit
SELECT 
    p.ProductName,
    p.Category,
    p.SubCategory,
    COUNT(DISTINCT od.OrderID) AS TimesOrdered,
    SUM(od.Quantity) AS TotalQuantitySold,
    ROUND(SUM(od.Sales), 2) AS TotalRevenue,
    ROUND(SUM(od.Profit), 2) AS TotalProfit,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) AS ProfitMargin
FROM products p
JOIN order_details od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category, p.SubCategory
ORDER BY SUM(od.Profit) DESC
LIMIT 10;

-- Step 4: Worst 10 Products by Profit
SELECT 
    p.ProductName,
    p.Category,
    p.SubCategory,
    COUNT(DISTINCT od.OrderID) AS TimesOrdered,
    SUM(od.Quantity) AS TotalQuantitySold,
    ROUND(SUM(od.Sales), 2) AS TotalRevenue,
    ROUND(SUM(od.Profit), 2) AS TotalLoss,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) AS ProfitMargin,
    ROUND(AVG(od.Discount) * 100, 2) AS AvgDiscountPercent
FROM products p
JOIN order_details od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category, p.SubCategory
HAVING SUM(od.Profit) < 0
ORDER BY SUM(od.Profit) ASC
LIMIT 10;

-- Step 5: Category Performance Analysis
SELECT 
    p.Category,
    COUNT(DISTINCT p.ProductID) AS TotalProducts,
    COUNT(DISTINCT od.OrderID) AS TotalOrders,
    SUM(od.Quantity) AS TotalQuantitySold,
    ROUND(SUM(od.Sales), 2) AS TotalRevenue,
    ROUND(SUM(od.Profit), 2) AS TotalProfit,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) AS ProfitMargin,
    ROUND(SUM(od.Sales) / COUNT(DISTINCT od.OrderID), 2) AS AvgSalePerOrder,
    ROUND(AVG(od.Discount) * 100, 2) AS AvgDiscountPercent,
    RANK() OVER (ORDER BY SUM(od.Sales) DESC) AS RevenueRank,
    RANK() OVER (ORDER BY SUM(od.Profit) DESC) AS ProfitRank
FROM products p
JOIN order_details od ON p.ProductID = od.ProductID
GROUP BY p.Category
ORDER BY SUM(od.Sales) DESC;

-- Step 6: Top 15 SubCategories by Revenue
SELECT 
    p.Category,
    p.SubCategory,
    COUNT(DISTINCT p.ProductID) AS TotalProducts,
    SUM(od.Quantity) AS TotalQuantitySold,
    ROUND(SUM(od.Sales), 2) AS TotalRevenue,
    ROUND(SUM(od.Profit), 2) AS TotalProfit,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) AS ProfitMargin,
    ROUND(AVG(od.Discount) * 100, 2) AS AvgDiscountPercent
FROM products p
JOIN order_details od ON p.ProductID = od.ProductID
GROUP BY p.Category, p.SubCategory
ORDER BY SUM(od.Sales) DESC
LIMIT 15;

-- Step 7: Regional Performance
SELECT 
    c.Region,
    COUNT(DISTINCT c.CustomerID) AS TotalCustomers,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    SUM(od.Quantity) AS TotalItems,
    ROUND(SUM(od.Sales), 2) AS TotalRevenue,
    ROUND(SUM(od.Profit), 2) AS TotalProfit,
    ROUND(SUM(od.Sales) / COUNT(DISTINCT o.OrderID), 2) AS AvgOrderValue,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) AS ProfitMargin,
    ROUND(SUM(od.Sales) / COUNT(DISTINCT c.CustomerID), 2) AS RevenuePerCustomer,
    ROUND(COUNT(DISTINCT o.OrderID) / COUNT(DISTINCT c.CustomerID), 2) AS OrdersPerCustomer,
    ROUND(AVG(od.Discount) * 100, 2) AS AvgDiscountPercent
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
GROUP BY c.Region
ORDER BY SUM(od.Sales) DESC;

-- Step 8: Top 15 Cities by Revenue
SELECT 
    c.City,
    c.State,
    c.Region,
    COUNT(DISTINCT c.CustomerID) AS TotalCustomers,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    ROUND(SUM(od.Sales), 2) AS TotalRevenue,
    ROUND(SUM(od.Profit), 2) AS TotalProfit,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) AS ProfitMargin,
    ROUND(SUM(od.Sales) / COUNT(DISTINCT c.CustomerID), 2) AS RevenuePerCustomer
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
GROUP BY c.City, c.State, c.Region
HAVING COUNT(DISTINCT o.OrderID) >= 10
ORDER BY SUM(od.Sales) DESC
LIMIT 15;

-- Step 9: Customer Segment Performance
SELECT 
    c.Segment,
    COUNT(DISTINCT c.CustomerID) AS TotalCustomers,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    ROUND(SUM(od.Sales), 2) AS TotalRevenue,
    ROUND(SUM(od.Profit), 2) AS TotalProfit,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) AS ProfitMargin,
    ROUND(SUM(od.Sales) / COUNT(DISTINCT o.OrderID), 2) AS AvgOrderValue,
    ROUND(SUM(od.Sales) / COUNT(DISTINCT c.CustomerID), 2) AS RevenuePerCustomer,
    ROUND(COUNT(DISTINCT o.OrderID) / COUNT(DISTINCT c.CustomerID), 2) AS OrdersPerCustomer,
    ROUND(AVG(od.Discount) * 100, 2) AS AvgDiscountPercent
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
GROUP BY c.Segment
ORDER BY SUM(od.Sales) DESC;

-- Step 10: Discount Impact Analysis
WITH discount_buckets AS (
    SELECT 
        CASE 
            WHEN od.Discount = 0 THEN 'No Discount'
            WHEN od.Discount <= 0.1 THEN '1-10% Discount'
            WHEN od.Discount <= 0.2 THEN '11-20% Discount'
            WHEN od.Discount <= 0.3 THEN '21-30% Discount'
            WHEN od.Discount <= 0.4 THEN '31-40% Discount'
            ELSE '40%+ Discount'
        END AS DiscountRange,
        od.OrderID,
        od.Sales,
        od.Profit,
        od.Discount
    FROM order_details od
)
SELECT 
    DiscountRange,
    COUNT(*) AS LineItemCount,
    COUNT(DISTINCT OrderID) AS OrderCount,
    ROUND(SUM(Sales), 2) AS TotalRevenue,
    ROUND(SUM(Profit), 2) AS TotalProfit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS ProfitMargin,
    ROUND(AVG(Sales), 2) AS AvgSaleAmount,
    ROUND(AVG(Discount) * 100, 2) AS AvgDiscountPercent
FROM discount_buckets
GROUP BY DiscountRange
ORDER BY 
    CASE DiscountRange
        WHEN 'No Discount' THEN 1
        WHEN '1-10% Discount' THEN 2
        WHEN '11-20% Discount' THEN 3
        WHEN '21-30% Discount' THEN 4
        WHEN '31-40% Discount' THEN 5
        ELSE 6
    END;

-- Step 11: Product Performance Summary (Executive KPIs)
-- Using subqueries to get proper counts
SELECT 'Total Products' AS Metric,
       COUNT(DISTINCT ProductID) AS Value,
       'Active products in catalog' AS Description
FROM products

UNION ALL
SELECT 'Profitable Products',
       COUNT(*) AS Value,
       'Products generating positive profit'
FROM (
    SELECT p.ProductID
    FROM products p
    JOIN order_details od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID
    HAVING SUM(od.Profit) > 0
) t

UNION ALL
SELECT 'Loss-Making Products',
       COUNT(*) AS Value,
       'Products generating losses'
FROM (
    SELECT p.ProductID
    FROM products p
    JOIN order_details od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID
    HAVING SUM(od.Profit) < 0
) t

UNION ALL
SELECT 'Products Driving 80% of Revenue',
       COUNT(*) AS Value,
       'Pareto principle: top products covering 80% revenue'
FROM (
    SELECT p.ProductID,
           SUM(od.Sales) AS Revenue,
           SUM(SUM(od.Sales)) OVER () AS TotalRevenue,
           SUM(SUM(od.Sales)) OVER (ORDER BY SUM(od.Sales) DESC) AS CumRevenue
    FROM products p
    JOIN order_details od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID
) ranked
WHERE CumRevenue <= 0.8 * TotalRevenue;