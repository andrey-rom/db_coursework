-- 1. Setup FDW to connect to the OLTP database (adjust host, dbname, port, user, password as needed)
DROP EXTENSION IF EXISTS postgres_fdw CASCADE;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

DROP SERVER IF EXISTS oltp_server CASCADE;
CREATE SERVER oltp_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', dbname 'Jewelry_OLTP', port '5432');

DROP USER MAPPING IF EXISTS FOR current_user SERVER oltp_server;
CREATE USER MAPPING FOR current_user
    SERVER oltp_server
    OPTIONS (user 'postgres', password 'your_password');

-- Import OLTP schema from the OLTP database into a foreign schema called oltp_fdw
DROP SCHEMA IF EXISTS oltp_fdw CASCADE;
CREATE SCHEMA oltp_fdw;
IMPORT FOREIGN SCHEMA public
    FROM SERVER oltp_server INTO oltp_fdw;


----------------------------
-- 2. Dimension Load Process
----------------------------

-- 2.1. Load Dim_Customer (SCD Type 2)
WITH current_customers AS (
    SELECT
        id AS customer_id,
        name,
        email,
        phone,
        -- Concatenate address details from the default address
        (SELECT CONCAT(address_line1, ', ', city, ', ', state, ', ', country)
         FROM oltp_fdw.Addresses
         WHERE customer_id = id AND is_default = TRUE
         LIMIT 1) AS address
    FROM oltp_fdw.Customers
),
changed_customers AS (
    SELECT cc.*
    FROM current_customers cc
    LEFT JOIN Dim_Customer dc 
         ON cc.customer_id = dc.customer_id AND dc.is_current = TRUE
    WHERE dc.customer_key IS NULL
       OR cc.name <> dc.name
       OR cc.email <> dc.email
       OR cc.phone <> dc.phone
       OR cc.address <> dc.address
),
closed_customers AS (
    UPDATE Dim_Customer
    SET end_date = CURRENT_DATE - 1, is_current = FALSE
    FROM changed_customers cc
    WHERE Dim_Customer.customer_id = cc.customer_id 
      AND Dim_Customer.is_current = TRUE
    RETURNING Dim_Customer.customer_id
)
INSERT INTO Dim_Customer (customer_id, name, email, phone, address, start_date, end_date, is_current)
SELECT 
    cc.customer_id,
    cc.name,
    cc.email,
    cc.phone,
    cc.address,
    CURRENT_DATE AS start_date,
    NULL::DATE AS end_date,
    TRUE AS is_current
FROM changed_customers cc;

-- 2.2. Load Dim_Product
INSERT INTO Dim_Product (product_id, name, category, price, material, brand)
SELECT 
    p.id,
    p.name,
    c.name AS category,
    p.price,
    p.material,
    p.brand
FROM oltp_fdw.Products p
LEFT JOIN oltp_fdw.Categories c ON p.category_id = c.id
LEFT JOIN Dim_Product dp ON dp.product_id = p.id
WHERE dp.product_id IS NULL;

-- 2.3. Load Dim_Time: Insert new dates from Orders.created_at
INSERT INTO Dim_Time (date, day, month, quarter, year)
SELECT DISTINCT
    o.created_at::DATE AS date,
    EXTRACT(DAY FROM o.created_at)::INT AS day,
    EXTRACT(MONTH FROM o.created_at)::INT AS month,
    EXTRACT(QUARTER FROM o.created_at)::INT AS quarter,
    EXTRACT(YEAR FROM o.created_at)::INT AS year
FROM oltp_fdw.Orders o
LEFT JOIN Dim_Time dt ON dt.date = o.created_at::DATE
WHERE dt.date IS NULL;

-- 2.4. Load Dim_Location: Use addresses from OLTP as shipping locations
INSERT INTO Dim_Location (city, state, country)
SELECT DISTINCT 
    a.city,
    a.state,
    a.country
FROM oltp_fdw.Addresses a
LEFT JOIN Dim_Location dl 
    ON dl.city = a.city AND dl.state = a.state AND dl.country = a.country
WHERE dl.location_key IS NULL;


----------------------------
-- 3. Fact Load Process
----------------------------

-- 3.1. Load Fact_Sales: Aggregate order details from OLTP Orders and Order_Details
INSERT INTO Fact_Sales (order_id, customer_key, product_ids, time_key, total_quantity, total_sales)
SELECT 
    o.id AS order_id,
    dc.customer_key,
    ARRAY_AGG(od.product_id) AS product_ids,
    dt.time_key,
    SUM(od.quantity) AS total_quantity,
    SUM(od.quantity * od.price) AS total_sales
FROM oltp_fdw.Orders o
LEFT JOIN Dim_Customer dc ON dc.customer_id = o.customer_id AND dc.is_current = TRUE
LEFT JOIN Dim_Time dt ON dt.date = o.created_at::DATE
LEFT JOIN oltp_fdw.Order_Details od ON o.id = od.order_id
LEFT JOIN Fact_Sales fs ON fs.order_id = o.id  -- Ensure only new orders are loaded
WHERE fs.order_id IS NULL
GROUP BY o.id, dc.customer_key, dt.time_key;

-- 3.2. Load Fact_Shipping: Insert shipping details based on order address
INSERT INTO Fact_Shipping (order_id, customer_key, location_key, time_key, shipping_status, shipping_cost, shipping_date)
SELECT 
    o.id AS order_id,
    dc.customer_key,
    dl.location_key,
    dt.time_key,
    CASE 
        WHEN o.order_status = 'Delivered' THEN 'Delivered'
        WHEN o.order_status = 'Cancelled' THEN 'Cancelled'
        ELSE 'Shipped'
    END AS shipping_status,
    0.00 AS shipping_cost,  -- Placeholder; update if you have shipping cost logic
    o.created_at::DATE AS shipping_date
FROM oltp_fdw.Orders o
LEFT JOIN Dim_Customer dc ON dc.customer_id = o.customer_id AND dc.is_current = TRUE
LEFT JOIN Dim_Time dt ON dt.date = o.created_at::DATE
LEFT JOIN (
    SELECT a.id, a.city, a.state, a.country,
           dl.location_key
    FROM oltp_fdw.Addresses a
    JOIN Dim_Location dl ON dl.city = a.city AND dl.state = a.state AND dl.country = a.country
) AS addr ON addr.id = o.address_id
LEFT JOIN Fact_Shipping fs ON fs.order_id = o.id
WHERE fs.order_id IS NULL;

