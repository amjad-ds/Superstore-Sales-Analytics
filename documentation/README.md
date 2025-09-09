# 🛒 Superstore Sales Analytics

## 📌 Project Overview
This project delivers an **end-to-end analytics solution** on the popular *Superstore dataset* using **MySQL + SQL analytics** and (later) **Power BI dashboards**.  

The work covers everything from **database design & normalization**, **ETL/data preparation**, to **advanced SQL analytics** (customer segmentation, sales trends, top performers) and finally **interactive dashboards** for business stakeholders.  

---

## 🏗️ Project Phases

### Phase 1: Environment Setup & Data Preparation ✅
- Created a **normalized relational schema**:
  - `customers`  
  - `products`  
  - `orders`  
  - `order_details`  
- Designed a **staging table** for raw CSV import.  
- Performed data cleaning, transformation, and migration into normalized tables.  
- Verified referential integrity and business logic.

### Phase 2: SQL Analytics Implementation ✅
Built advanced SQL queries for **business intelligence reporting**:

- **Customer Segmentation (RFM Analysis)**  
  - Recency, Frequency, Monetary scoring  
  - Tiered segments (Gold, Silver, Bronze)  
  - Reports: Segment distribution, at-risk customers, champions, regional breakdowns  

- **Sales Trend Analysis**  
  - Monthly/quarterly/yearly revenue growth  
  - Seasonal patterns & YoY comparisons  
  - Best/worst performing months  

- **Performance Analytics**  
  - Top 10 customers, products, categories  
  - Regional & segment performance  
  - Discount impact analysis  

- **Advanced SQL Objects**  
  - **Views**: sales_overview_dashboard, customer_performance_view, product_performance_view, regional_performance_view  
  - **Stored Procedures**: daily sales summary, customer analysis, product performance, monthly executive dashboard  

### Phase 3: Power BI Dashboard (Work in Progress 🚧)
Planned dashboard pages:  
1. **Executive Overview** → KPIs, revenue trends, YoY growth  
2. **Customer Analytics** → RFM segments, CLV, retention  
3. **Regional Performance** → Geographic breakdowns  
4. **Product Analysis** → Category & product profitability  

Interactive features:  
- Time slicers, regional filters, KPI cards  

### Phase 4: Optional Python ML Extension 🤖
- **Sales Forecasting** → ARIMA/Prophet for quarterly predictions  
- **Customer Churn Prediction** → Classification models using RFM features  

---

## 📂 Repository Structure

superstore-analytics/
│
├── sql/ # SQL scripts
│ ├── 01_database_setup.sql
│ ├── 02_data_import.sql
│ ├── 05_rfm_analysis_fixed.sql
│ ├── 06_sales_trends_simplified.sql
│ ├── 07_top_performers_analysis.sql
│ └── 08_views_and_procedures.sql
│
├── documentation/ # Documentation & reports
│ ├── README.md # This file
│ ├── project_presentation.pptx
│ └── dashboard_screenshots/
│
├── powerbi/ # To be added later
│ └── superstore_dashboard.pbix
│
└── python/ (optional) # ML extensions
├── sales_forecasting.ipynb
└── churn_prediction.ipynb

---

## 📊 Key Insights (So Far)
- **Customer Champions** contribute disproportionately to total revenue.  
- **Seasonal peaks** around November–December (holiday shopping effect).  
- Certain **categories/products consistently underperform**, driving losses.  
- **Discounts beyond a threshold reduce profitability** significantly.  

---

## 🚀 Future Roadmap
- [ ] Build Power BI dashboards for executive decision-making  
- [ ] Add predictive sales forecasting using Python  
- [ ] Deploy churn prediction model for customer retention strategies  

---

## 👨‍💻 Author
**Syed Mohammed Amjad**  
📧 shaik.amer2000s967@gmail.com
