DROP TABLE IF EXISTS Fact_Shipping CASCADE;
DROP TABLE IF EXISTS Fact_Sales CASCADE;
DROP TABLE IF EXISTS Dim_Location CASCADE;
DROP TABLE IF EXISTS Dim_Time CASCADE;
DROP TABLE IF EXISTS Dim_Product CASCADE;
DROP TABLE IF EXISTS Dim_Customer CASCADE;

-- Dimension: Dim_Customer (SCD Type 2)
CREATE TABLE Dim_Customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,         -- Original OLTP customer id
    name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    start_date DATE NOT NULL,         -- When this version became effective
    end_date DATE,                    -- End of validity (NULL if current)
    is_current BOOLEAN NOT NULL       -- TRUE if this is the current record
);

-- Dimension: Dim_Product
CREATE TABLE Dim_Product (
    product_key SERIAL PRIMARY KEY,
    product_id INT NOT NULL,          -- Original OLTP product id
    name TEXT,
    category TEXT,
    price NUMERIC(10,2),
    material TEXT,
    brand TEXT
);

-- Dimension: Dim_Time
CREATE TABLE Dim_Time (
    time_key SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    day INT,
    month INT,
    quarter INT,
    year INT
);

-- Dimension: Dim_Location
-- This can capture shipping destination details
CREATE TABLE Dim_Location (
    location_key SERIAL PRIMARY KEY,
    city TEXT,
    state TEXT,
    country TEXT
);

-- Fact Table: Fact_Sales
-- Aggregates order-level sales data from the OLTP system
CREATE TABLE Fact_Sales (
    order_id INT PRIMARY KEY,         -- Matches OLTP order id
    customer_key INT REFERENCES Dim_Customer(customer_key),
    product_ids INT[],                -- Aggregated array of product ids in the order
    time_key INT REFERENCES Dim_Time(time_key),
    total_quantity INT,               -- Sum of all product quantities in the order
    total_sales NUMERIC(10,2)         -- Sum of the order's total amount
);

-- Fact Table: Fact_Shipping
-- Captures shipping details for orders (repurposed from the food delivery fact)
CREATE TABLE Fact_Shipping (
    shipping_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES Fact_Sales(order_id),
    customer_key INT REFERENCES Dim_Customer(customer_key),
    location_key INT REFERENCES Dim_Location(location_key),
    time_key INT REFERENCES Dim_Time(time_key),
    shipping_status TEXT,             -- e.g., 'Shipped', 'Delivered'
    shipping_cost NUMERIC(10,2),        -- Shipping cost if applicable
    shipping_date DATE                -- Date the order was shipped/delivered
);
