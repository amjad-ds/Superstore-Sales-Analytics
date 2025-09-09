-- =====================================================
-- SALES TREND ANALYSIS - Growth Patterns & Forecasting
-- File: 04_sales_trends.sql
-- =====================================================

-- Step 1: Monthly Sales Trends with Growth Rates
CREATE OR REPLACE VIEW monthly_sales_trends AS
WITH monthly_data AS (
    SELECT 
        YEAR(o.OrderDate) as SalesYear,
        MONTH(o.OrderDate) as SalesMonth,
        DATE_FORMAT(o.OrderDate, '%Y-%m') as YearMonth,
        COUNT(DISTINCT o.OrderID) as Orders,
        COUNT(DISTINCT o.CustomerID) as UniqueCustomers,
        ROUND(SUM(od.Sales), 2) as Revenue,
        ROUND(SUM(od.Profit), 2) as Profit,
        ROUND(SUM(od.Sales) / COUNT(DISTINCT o.OrderID), 2) AS AvgOrderValue,
        SUM(od.Quantity) as TotalQuantity
    FROM orders o
    JOIN order_details od ON o.OrderID = od.OrderID
    GROUP BY YearMonth, SalesYear, SalesMonth
)
SELECT 
    SalesYear,
    SalesMonth,
    YearMonth,
    Orders,
    UniqueCustomers,
    Revenue,
    Profit,
    AvgOrderValue,
    TotalQuantity,
    
    -- Previous month revenue
    LAG(Revenue, 1) OVER (ORDER BY SalesYear, SalesMonth) as PrevMonthRevenue,
    -- Same month last year revenue
    LAG(Revenue, 12) OVER (ORDER BY SalesYear, SalesMonth) as SameMonthLastYear,
    
    -- Month-over-Month Growth
    CASE 
        WHEN LAG(Revenue, 1) OVER (ORDER BY SalesYear, SalesMonth) IS NOT NULL 
        THEN ROUND(((Revenue - LAG(Revenue, 1) OVER (ORDER BY SalesYear, SalesMonth)) / 
                    LAG(Revenue, 1) OVER (ORDER BY SalesYear, SalesMonth) * 100), 2)
        ELSE NULL 
    END as MoM_Growth_Percent,
    
    -- Year-over-Year Growth
    CASE 
        WHEN LAG(Revenue, 12) OVER (ORDER BY SalesYear, SalesMonth) IS NOT NULL 
        THEN ROUND(((Revenue - LAG(Revenue, 12) OVER (ORDER BY SalesYear, SalesMonth)) / 
                    LAG(Revenue, 12) OVER (ORDER BY SalesYear, SalesMonth) * 100), 2)
        ELSE NULL 
    END as YoY_Growth_Percent,
    
    -- Profit Margin
    ROUND((Profit / Revenue * 100), 2) as ProfitMargin
    
FROM monthly_data
ORDER BY SalesYear, SalesMonth;

-- Step 2: Quarterly Performance Analysis
CREATE OR REPLACE VIEW quarterly_performance AS
SELECT 
    SalesYear,
    CASE 
        WHEN SalesMonth IN (1,2,3) THEN 'Q1'
        WHEN SalesMonth IN (4,5,6) THEN 'Q2'
        WHEN SalesMonth IN (7,8,9) THEN 'Q3'
        ELSE 'Q4'
    END as Quarter,
    ROUND(SUM(Revenue), 2) as QuarterlyRevenue,
    ROUND(SUM(Profit), 2) as QuarterlyProfit,
    ROUND(AVG(AvgOrderValue), 2) as AvgOrderValue,
    SUM(Orders) as TotalOrders,
    SUM(UniqueCustomers) as TotalCustomers,
    ROUND(SUM(Profit) / SUM(Revenue) * 100, 2) as ProfitMargin
FROM monthly_sales_trends
GROUP BY SalesYear, 
    CASE 
        WHEN SalesMonth IN (1,2,3) THEN 'Q1'
        WHEN SalesMonth IN (4,5,6) THEN 'Q2'
        WHEN SalesMonth IN (7,8,9) THEN 'Q3'
        ELSE 'Q4'
    END
ORDER BY SalesYear, Quarter;

-- Step 3: Category Performance Over Time
CREATE OR REPLACE VIEW category_monthly_trends AS
SELECT 
    DATE_FORMAT(o.OrderDate, '%Y-%m') as YearMonth,
    YEAR(o.OrderDate) as SalesYear,
    MONTH(o.OrderDate) as SalesMonth,
    p.Category,
    ROUND(SUM(od.Sales), 2) as Revenue,
    ROUND(SUM(od.Profit), 2) as Profit,
    COUNT(DISTINCT o.OrderID) as Orders,
    ROUND(SUM(od.Profit) / SUM(od.Sales) * 100, 2) as ProfitMargin
FROM orders o
JOIN order_details od ON o.OrderID = od.OrderID  
JOIN products p ON od.ProductID = p.ProductID
GROUP BY DATE_FORMAT(o.OrderDate, '%Y-%m'), YEAR(o.OrderDate), MONTH(o.OrderDate), p.Category
ORDER BY YearMonth, Revenue DESC;

-- REPORTING QUERIES --

-- Report 1: Overall Sales Performance Summary
SELECT 
    COUNT(DISTINCT YearMonth) as TotalMonths,
    CONCAT('$', FORMAT(MIN(Revenue), 2)) as LowestMonthlyRevenue,
    CONCAT('$', FORMAT(MAX(Revenue), 2)) as HighestMonthlyRevenue,
    CONCAT('$', FORMAT(AVG(Revenue), 2)) as AvgMonthlyRevenue,
    CONCAT('$', FORMAT(SUM(Revenue), 2)) as TotalRevenue,
    ROUND(AVG(CASE WHEN MoM_Growth_Percent IS NOT NULL THEN MoM_Growth_Percent END), 2) as AvgMoMGrowth,
    ROUND(AVG(CASE WHEN YoY_Growth_Percent IS NOT NULL THEN YoY_Growth_Percent END), 2) as AvgYoYGrowth,
    ROUND(SUM(Profit) / SUM(Revenue) * 100, 2) as AvgProfitMargin
FROM monthly_sales_trends;

-- Report 2: Best and Worst Performing Months
SELECT 
    YearMonth,
    CONCAT('$', FORMAT(Revenue, 2)) as Revenue,
    Orders,
    CONCAT(IFNULL(MoM_Growth_Percent, 0), '%') as MoM_Growth,
    CONCAT(IFNULL(YoY_Growth_Percent, 0), '%') as YoY_Growth,
    CONCAT(ProfitMargin, '%') as ProfitMargin
FROM monthly_sales_trends
ORDER BY Revenue DESC
LIMIT 5;

SELECT 
    YearMonth,
    CONCAT('$', FORMAT(Revenue, 2)) as Revenue,
    Orders,
    CONCAT(IFNULL(MoM_Growth_Percent, 0), '%') as MoM_Growth,
    CONCAT(IFNULL(YoY_Growth_Percent, 0), '%') as YoY_Growth,
    CONCAT(ProfitMargin, '%') as ProfitMargin
FROM monthly_sales_trends
ORDER BY Revenue ASC
LIMIT 5;

-- Report 3: Quarterly Performance Analysis
SELECT 
    CONCAT(SalesYear, ' ', Quarter) as Period,
    CONCAT('$', FORMAT(QuarterlyRevenue, 2)) as Revenue,
    CONCAT('$', FORMAT(QuarterlyProfit, 2)) as Profit,
    CONCAT(ProfitMargin, '%') as ProfitMargin,
    TotalOrders as Orders,
    TotalCustomers as UniqueCustomers,
    CONCAT('$', FORMAT(AvgOrderValue, 2)) as AvgOrderValue
FROM quarterly_performance
ORDER BY SalesYear, Quarter;

-- Report 4: Year-over-Year Growth Analysis
SELECT 
    YearMonth,
    CONCAT('$', FORMAT(Revenue, 2)) as Revenue,
    CONCAT(IFNULL(YoY_Growth_Percent, 'N/A'), '%') as YoY_Growth,
    CASE 
        WHEN YoY_Growth_Percent > 20 THEN 'Excellent Growth'
        WHEN YoY_Growth_Percent > 10 THEN 'Good Growth'  
        WHEN YoY_Growth_Percent > 0 THEN 'Positive Growth'
        WHEN YoY_Growth_Percent IS NULL THEN 'No Comparison'
        ELSE 'Declining'
    END as GrowthStatus
FROM monthly_sales_trends
WHERE YoY_Growth_Percent IS NOT NULL
ORDER BY YoY_Growth_Percent DESC;

-- Report 5: Seasonal Pattern Analysis
SELECT 
    CASE 
        WHEN SalesMonth IN (12,1,2) THEN 'Winter'
        WHEN SalesMonth IN (3,4,5) THEN 'Spring'
        WHEN SalesMonth IN (6,7,8) THEN 'Summer'
        ELSE 'Fall'
    END as Season,
    COUNT(*) as TotalMonths,
    CONCAT('$', FORMAT(AVG(Revenue), 2)) as AvgMonthlyRevenue,
    CONCAT('$', FORMAT(SUM(Revenue), 2)) as TotalRevenue,
    ROUND(AVG(Orders), 0) as AvgMonthlyOrders,
    ROUND(SUM(Profit) / SUM(Revenue) * 100, 2) as AvgProfitMargin
FROM monthly_sales_trends
GROUP BY 
    CASE 
        WHEN SalesMonth IN (12,1,2) THEN 'Winter'
        WHEN SalesMonth IN (3,4,5) THEN 'Spring'
        WHEN SalesMonth IN (6,7,8) THEN 'Summer'
        ELSE 'Fall'
    END
ORDER BY AVG(Revenue) DESC;

-- Report 6: Category Performance Summary  
SELECT 
    Category,
    CONCAT('$', FORMAT(SUM(Revenue), 2)) as TotalRevenue,
    ROUND(SUM(Profit) / SUM(Revenue) * 100, 2) as AvgProfitMargin,
    COUNT(DISTINCT YearMonth) as MonthsActive,
    CONCAT('$', FORMAT(SUM(Revenue) / COUNT(DISTINCT YearMonth), 2)) as AvgMonthlyRevenue,
    SUM(Orders) as TotalOrders
FROM category_monthly_trends
GROUP BY Category
ORDER BY SUM(Revenue) DESC;

-- Report 7: Monthly Growth Trend Summary
SELECT 
    'Positive MoM Growth' as MetricType,
    SUM(CASE WHEN MoM_Growth_Percent > 0 THEN 1 ELSE 0 END) as Count,
    ROUND(SUM(CASE WHEN MoM_Growth_Percent > 0 THEN 1 ELSE 0 END) * 100.0 / 
          SUM(CASE WHEN MoM_Growth_Percent IS NOT NULL THEN 1 ELSE 0 END), 1) as Percentage,
    ROUND(AVG(CASE WHEN MoM_Growth_Percent > 0 THEN MoM_Growth_Percent END), 2) as AvgGrowthRate
FROM monthly_sales_trends
UNION ALL
SELECT 
    'Positive YoY Growth',
    SUM(CASE WHEN YoY_Growth_Percent > 0 THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN YoY_Growth_Percent > 0 THEN 1 ELSE 0 END) * 100.0 / 
          SUM(CASE WHEN YoY_Growth_Percent IS NOT NULL THEN 1 ELSE 0 END), 1),
    ROUND(AVG(CASE WHEN YoY_Growth_Percent > 0 THEN YoY_Growth_Percent END), 2)
FROM monthly_sales_trends;