OLTP Schema

Schema Overview:
The OLTP database is designed to support the full user action flow for the jewelry store. It is implemented in 3NF and comprises eight tables:

Customers: Stores customer information (name, email, password, phone, created_at).
Addresses: Contains customer addresses (linked to Customers).
Categories: Holds jewelry categories (e.g., Rings, Necklaces, Bracelets).
Products: Contains product details including jewelry-specific attributes (name, description, price, material, brand, availability status) and links to Categories.
Orders: Captures order details placed by customers (total cost, order status, payment method, created_at).
Order_Details: Records individual items within an order (quantity, price).
Admins: Manages administrative users.
Liked_Products: Tracks products that customers like, supporting user account features.
File Names:

OLTP script: J_OLTP.sql

2. Data Loading to OLTP (File Parsing ETL)

ETL Overview:
A file parsing ETL script (written in SQL) loads data from CSV files into the OLTP database. The script uses staging tables, the PostgreSQL COPY command, and LEFT JOINs to ensure that only new records are inserted (thus making the script rerunnable).

Instructions:

Place your CSV files (e.g., Customers.csv, Addresses.csv, Products.csv, Orders.csv, OrderDetails.csv) in the designated folder (e.g., the “Postgres” folder) so that the COPY commands work correctly.
Adjust file paths in the Jewelry_FileParsing_ETL.sql script.
Execute the ETL script on your OLTP database.
Note:
Only two CSV files (Customers and Products) should be free of surrogate keys; other files may include surrogate keys if needed.

File Name:

File Parsing ETL: J_FileParsing_ETL.sql


3. OLAP Schema

Schema Overview:
The OLAP solution is built as a multidimensional data warehouse using a snowflake schema. It is stored separately from the OLTP database and contains aggregations to support analytical queries.

Dimensions:
Dim_Customer (SCD Type 2): Tracks customer data changes over time.
Dim_Product: Contains jewelry product details.
Dim_Time: A date dimension for time-based aggregations.
Dim_Location: Captures shipping or regional data based on customer addresses.
Fact Tables:
Fact_Sales: Aggregates order-level data, including total quantity and sales, and stores an aggregated array of product IDs.
Fact_Shipping: Captures shipping-related details (e.g., shipping status, cost, date).
File Names:

OLAP script: J_OLAP.sql

4. ETL from OLTP to OLAP

ETL Overview:
An ETL script transfers and transforms data from the OLTP system to the OLAP data warehouse. It uses PostgreSQL Foreign Data Wrappers (FDW) to connect to the OLTP database, extracts new or changed data, and loads it into the OLAP dimensions and fact tables.

Instructions:

In the first half of the script, update the OLTP connection details (host, port, database name, user, password).
Execute the first half of the script in your OLAP database to set up FDW, server, and schema import.
Run the remaining part of the script to load data into OLAP tables.
File Name:

ETL from OLTP to OLAP: J_OLTPtoOLAP_ETL.sql

5. Analytical Queries

OLTP Queries:
Example: Querying orders per customer over the last month and identifying the top 5 most frequently ordered products.
OLAP Queries:
Example: Aggregating monthly orders and total revenue by jewelry category over the last year.
Purpose:
These queries provide insights into transactional behavior and aggregated analytics, meeting the coursework requirements.
