-- =====================================================
-- SUPERSTORE ANALYTICS PROJECT - DATABASE SETUP
-- File: 01_database_setup.sql
-- =====================================================

-- Step 1: Create Database
CREATE DATABASE IF NOT EXISTS superstore_analytics;
USE superstore_analytics;

-- Step 2: Create Customers Table
CREATE TABLE customers (
    CustomerID VARCHAR(20) PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    Segment VARCHAR(20) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    City VARCHAR(50) NOT NULL,
    State VARCHAR(50) NOT NULL,
    PostalCode VARCHAR(10),
    Region VARCHAR(20) NOT NULL,
    INDEX idx_segment (Segment),
    INDEX idx_region (Region)
);

-- Step 3: Create Products Table
CREATE TABLE products (
    ProductID VARCHAR(20) PRIMARY KEY,
    Category VARCHAR(50) NOT NULL,
    SubCategory VARCHAR(50) NOT NULL,
    ProductName VARCHAR(200) NOT NULL,
    INDEX idx_category (Category),
    INDEX idx_subcategory (SubCategory)
);

-- Step 4: Create Orders Table
CREATE TABLE orders (
    OrderID VARCHAR(20) PRIMARY KEY,
    CustomerID VARCHAR(20) NOT NULL,
    OrderDate DATE NOT NULL,
    ShipDate DATE NOT NULL,
    ShipMode VARCHAR(20) NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID),
    INDEX idx_order_date (OrderDate),
    INDEX idx_customer_id (CustomerID)
);

-- Step 5: Create Order Details Table
CREATE TABLE order_details (
    OrderDetailID INT AUTO_INCREMENT PRIMARY KEY,
    RowID INT NOT NULL,
    OrderID VARCHAR(20) NOT NULL,
    ProductID VARCHAR(20) NOT NULL,
    Sales DECIMAL(15,6) NOT NULL,      
    Quantity INT NOT NULL,
    Discount DECIMAL(5,4) NOT NULL DEFAULT 0 CHECK (Discount >= 0 AND Discount <= 1),  -- Enforce 0–1 range
    Profit DECIMAL(15,6) NOT NULL,     
    FOREIGN KEY (OrderID) REFERENCES orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES products(ProductID),
    INDEX idx_order_id (OrderID),
    INDEX idx_product_id (ProductID)
);

-- Step 6: Create Staging Table for CSV Import
CREATE TABLE staging_superstore (
    RowID TEXT,
    OrderID TEXT,
    OrderDate TEXT,
    ShipDate TEXT,
    ShipMode TEXT,
    CustomerID TEXT,
    CustomerName TEXT,
    Segment TEXT,
    Country TEXT,
    City TEXT,
    State TEXT,
    PostalCode TEXT,
    Region TEXT,
    ProductID TEXT,
    Category TEXT,
    SubCategory TEXT,
    ProductName TEXT,
    Sales TEXT,
    Quantity TEXT,
    Discount TEXT,
    Profit TEXT
);

-- Verify tables created
SHOW TABLES;