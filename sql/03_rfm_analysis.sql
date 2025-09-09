-- =====================================================
-- RFM CUSTOMER SEGMENTATION ANALYSIS - MySQL Compatible
-- File: 03_rfm_analysis.sql
-- =====================================================

-- Step 1: Calculate RFM Metrics for each customer
CREATE OR REPLACE VIEW customer_rfm_base AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Segment,
    c.Region,
    
    -- RECENCY: Days since last purchase (relative to dataset max date)
    DATEDIFF((SELECT MAX(OrderDate) FROM orders), MAX(o.OrderDate)) as Recency,
    
    -- FREQUENCY: Number of orders
    COUNT(DISTINCT o.OrderID) as Frequency,
    
    -- MONETARY: Total spend
    ROUND(SUM(od.Sales), 2) as Monetary,

    -- Additional metrics
    ROUND(AVG(od.Sales), 2) as AvgOrderValue,
    SUM(od.Quantity) as TotalQuantityBought,
    ROUND(SUM(od.Profit), 2) as TotalProfit,
    MIN(o.OrderDate) as FirstOrderDate,
    MAX(o.OrderDate) as LastOrderDate,
    DATEDIFF(MAX(o.OrderDate), MIN(o.OrderDate)) as CustomerLifespanDays
    
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.CustomerName, c.Segment, c.Region;

-- Step 2: Create RFM Scores using NTILE function
CREATE OR REPLACE VIEW customer_rfm_scores AS
SELECT *,
    -- Use NTILE to divide customers into 4 quartiles
    -- For Recency: Lower values are better, so we reverse the score
    (5 - NTILE(4) OVER (ORDER BY Recency)) as R_Score,
    
    -- For Frequency: Higher values are better
    NTILE(4) OVER (ORDER BY Frequency) as F_Score,
    
    -- For Monetary: Higher values are better  
    NTILE(4) OVER (ORDER BY Monetary) as M_Score
    
FROM customer_rfm_base;

-- Step 3: Create Customer Segments Based on RFM Scores
CREATE OR REPLACE VIEW customer_segments AS
SELECT *,
    CONCAT(R_Score, F_Score, M_Score) as RFM_Score,
    
    -- Segment customers into meaningful business categories
    CASE 
        -- Best customers
        WHEN R_Score = 4 AND F_Score = 4 AND M_Score = 4 THEN 'Champions'
        WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3 THEN 'Loyal Customers'
        
        -- Good recent but still growing
        WHEN R_Score = 4 AND F_Score <= 2 AND M_Score >= 3 THEN 'Potential Loyalists'
        WHEN R_Score = 4 AND F_Score <= 2 AND M_Score <= 2 THEN 'New Customers'
        WHEN R_Score = 3 AND F_Score >= 2 AND M_Score >= 2 THEN 'Promising'
        
        -- Customers with risk signals
        WHEN R_Score = 2 AND F_Score >= 3 AND M_Score <= 2 THEN 'About to Sleep'
        WHEN R_Score <= 2 AND F_Score >= 4 AND M_Score >= 3 THEN 'At Risk'
        WHEN R_Score = 1 AND F_Score >= 4 AND M_Score >= 3 THEN 'Cannot Lose Them'
        
        -- Low recency, some value
        WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score >= 3 THEN 'Hibernating'
        
        -- Everyone else
        ELSE 'Lost'
    END as CustomerSegment,
    
    -- Simple Value Tier
    CASE 
        WHEN (R_Score + F_Score + M_Score) >= 10 THEN 'High Value'
        WHEN (R_Score + F_Score + M_Score) >= 7 THEN 'Medium Value' 
        ELSE 'Low Value'
    END as ValueTier
    
FROM customer_rfm_scores;

-- Step 4: RFM Analysis Summary Reports
-- =================================
-- RFM CUSTOMER SEGMENTATION REPORTS
-- =================================


-- Report 1: Customer Segment Distribution
SELECT 
    CustomerSegment,
    COUNT(*) as CustomerCount,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_segments), 1) as Percentage,
    ROUND(AVG(Monetary), 2) as AvgSpend,
    ROUND(SUM(Monetary), 2) as TotalRevenue,
    ROUND(AVG(Frequency), 1) as AvgOrders,
    ROUND(AVG(Recency), 0) as AvgDaysSinceLastOrder
FROM customer_segments
GROUP BY CustomerSegment
ORDER BY TotalRevenue DESC;


-- Report 2: Value Tier Analysis
SELECT 
    COUNT(*) as Customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_segments), 1) as Percentage,
    ROUND(SUM(Monetary), 2) as TotalRevenue,
    ROUND(AVG(Monetary), 2) as AvgRevenuePerCustomer,
    ROUND(SUM(Monetary) * 100.0 / (SELECT SUM(Monetary) FROM customer_segments), 1) as RevenuePercentage
FROM customer_segments
GROUP BY ValueTier
ORDER BY TotalRevenue DESC;


-- Report 3: Top 20 Champions (Best Customers)
SELECT 
    CustomerName,
    Segment,
    Region,
    RFM_Score,
    ROUND(Monetary, 2) as TotalSpend,
    Frequency as Orders,
    Recency as DaysSinceLastOrder,
    ROUND(AvgOrderValue, 2) as AvgOrderValue,
    ROUND(TotalProfit, 2) as TotalProfit
FROM customer_segments
WHERE CustomerSegment = 'Champions'
ORDER BY Monetary DESC
LIMIT 20;


-- Report 4: At-Risk Customers (Need Immediate Attention)
SELECT 
    CustomerName,
    Segment,
    Region,
    RFM_Score,
    ROUND(Monetary, 2) as TotalSpend,
    Frequency as Orders,
    Recency as DaysSinceLastOrder,
    LastOrderDate,
    CustomerSegment
FROM customer_segments
WHERE CustomerSegment IN ('At Risk', 'Cannot Lose Them', 'About to Sleep')
ORDER BY Monetary DESC
LIMIT 20;


-- Report 5: Regional RFM Performance
SELECT 
    Region,
    COUNT(*) as TotalCustomers,
    ROUND(AVG(Monetary), 2) as AvgSpendPerCustomer,
    ROUND(SUM(Monetary), 2) as TotalRevenue,
    ROUND(AVG(Frequency), 1) as AvgOrdersPerCustomer,
    ROUND(AVG(Recency), 0) as AvgDaysSinceLastOrder,
    COUNT(CASE WHEN ValueTier = 'High Value' THEN 1 END) as HighValueCustomers,
    ROUND(COUNT(CASE WHEN ValueTier = 'High Value' THEN 1 END) * 100.0 / COUNT(*), 1) as HighValuePercentage
FROM customer_segments
GROUP BY Region
ORDER BY SUM(Monetary) DESC;


-- Report 6: RFM Score Distribution
SELECT 
    CONCAT('R:', R_Score, ' F:', F_Score, ' M:', M_Score) as RFM_Breakdown,
    COUNT(*) as CustomerCount,
    ROUND(AVG(Monetary), 2) as AvgSpend,
    CustomerSegment
FROM customer_segments
GROUP BY R_Score, F_Score, M_Score, CustomerSegment
HAVING COUNT(*) >= 5
ORDER BY CustomerCount DESC;


-- Report 7: Business Recommendations Based on Segments
SELECT 
    CustomerSegment,
    COUNT(*) as CustomerCount,
    ROUND(SUM(Monetary), 2) as TotalRevenue,
    CASE CustomerSegment
        WHEN 'Champions' THEN 'Reward them! VIP treatment, exclusive offers, early access to new products'
        WHEN 'Loyal Customers' THEN 'Upsell premium products, loyalty program, referral incentives'
        WHEN 'Potential Loyalists' THEN 'Offer membership, recommend products, cross-sell opportunities'
        WHEN 'New Customers' THEN 'Welcome series, onboarding support, build relationship'
        WHEN 'Promising' THEN 'Create brand awareness, free trials, special offers'
        WHEN 'Need Attention' THEN 'Limited time offers, reactivation campaigns, surveys'
        WHEN 'About to Sleep' THEN 'Win-back campaigns, renewal offers, personalized recommendations'
        WHEN 'At Risk' THEN 'Urgent retention campaigns, feedback surveys, special discounts'
        WHEN 'Cannot Lose Them' THEN 'Win them back at all costs, personal contact, exclusive deals'
        WHEN 'Hibernating' THEN 'Reactivation campaigns, new product announcements'
        ELSE 'Ignore or very low-cost campaigns'
    END as RecommendedAction
FROM customer_segments
GROUP BY CustomerSegment
ORDER BY SUM(Monetary) DESC;