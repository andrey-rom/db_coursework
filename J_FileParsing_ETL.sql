-- Enable necessary extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create temporary staging tables for CSV data
CREATE TEMP TABLE Staging_Customers (
    "Full name" TEXT,
    Email TEXT,
    Password TEXT,
    Phone TEXT,
    "Creation Date & Time" TIMESTAMP
);

CREATE TEMP TABLE Staging_Products (
    Name TEXT,
    Description TEXT,
    Price NUMERIC(10,2),
    "Category name" TEXT,
    "Availability status" BOOLEAN,
    material TEXT,
    brand TEXT
);

CREATE TEMP TABLE Staging_Addresses (
    customer_id INT,
    address_line1 TEXT,
    address_line2 TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    is_default BOOLEAN
);

CREATE TEMP TABLE Staging_Orders (
    customer_id INT,
    address_id INT,
    total_cost NUMERIC(10,2),
    order_status TEXT,
    payment_method TEXT,
    created_at TIMESTAMP
);

CREATE TEMP TABLE Staging_Order_Details (
    order_id INT,
    product_id INT,
    quantity INT,
    price NUMERIC(10,2)
);

-- Load data from CSV files into staging tables (adjust file paths as necessary)
COPY Staging_Customers("Full name", Email, Password, Phone, "Creation Date & Time")
FROM '/path/to/customers.csv'
WITH (FORMAT CSV, HEADER TRUE);

COPY Staging_Products(Name, Description, Price, "Category name", "Availability status", material, brand)
FROM '/path/to/products.csv'
WITH (FORMAT CSV, HEADER TRUE);

COPY Staging_Addresses(customer_id, address_line1, address_line2, city, state, country, is_default)
FROM '/path/to/addresses.csv'
WITH (FORMAT CSV, HEADER TRUE);

COPY Staging_Orders(customer_id, address_id, total_cost, order_status, payment_method, created_at)
FROM '/path/to/orders.csv'
WITH (FORMAT CSV, HEADER TRUE);

COPY Staging_Order_Details(order_id, product_id, quantity, price)
FROM '/path/to/orderDetails.csv'
WITH (FORMAT CSV, HEADER TRUE);

-- Insert new customers into the Customers table
INSERT INTO Customers (name, email, password, phone, created_at)
SELECT s."Full name", s.Email, s.Password, s.Phone, s."Creation Date & Time"
FROM Staging_Customers s
LEFT JOIN Customers c ON s.Email = c.email
WHERE c.email IS NULL;

-- Insert missing categories into the Categories table
INSERT INTO Categories (name)
SELECT DISTINCT s."Category name"
FROM Staging_Products s
LEFT JOIN Categories c ON s."Category name" = c.name
WHERE c.name IS NULL;

-- Insert new products into the Products table
INSERT INTO Products (name, description, price, category_id, availability_status, material, brand)
SELECT 
    s.Name, 
    s.Description, 
    s.Price, 
    c.id, 
    s."Availability status",
    s.material,
    s.brand
FROM Staging_Products s
LEFT JOIN Categories c ON s."Category name" = c.name
LEFT JOIN Products p ON s.Name = p.name AND c.id = p.category_id
WHERE p.name IS NULL AND c.id IS NOT NULL;

-- Insert new addresses into the Addresses table
INSERT INTO Addresses (customer_id, address_line1, address_line2, city, state, country, is_default)
SELECT s.customer_id, s.address_line1, s.address_line2, s.city, s.state, s.country, s.is_default
FROM Staging_Addresses s
LEFT JOIN Addresses a ON s.customer_id = a.customer_id AND s.address_line1 = a.address_line1
WHERE a.customer_id IS NULL;

-- Insert new orders into the Orders table
INSERT INTO Orders (customer_id, address_id, total_cost, order_status, payment_method, created_at)
SELECT s.customer_id, s.address_id, s.total_cost, s.order_status, s.payment_method, s.created_at
FROM Staging_Orders s
LEFT JOIN Orders o ON s.customer_id = o.customer_id AND s.created_at = o.created_at
WHERE o.id IS NULL;

-- Insert new order details into the Order_Details table
INSERT INTO Order_Details (order_id, product_id, quantity, price)
SELECT s.order_id, s.product_id, s.quantity, s.price
FROM Staging_Order_Details s
LEFT JOIN Order_Details od ON s.order_id = od.order_id AND s.product_id = od.product_id
WHERE od.id IS NULL;

-- Clean up temporary staging tables
DROP TABLE Staging_Customers;
DROP TABLE Staging_Products;
DROP TABLE Staging_Addresses;
DROP TABLE Staging_Orders;
DROP TABLE Staging_Order_Details;
