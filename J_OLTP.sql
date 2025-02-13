DROP TABLE IF EXISTS Order_Details CASCADE;
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS Liked_Products CASCADE;
DROP TABLE IF EXISTS Products CASCADE;
DROP TABLE IF EXISTS Categories CASCADE;
DROP TABLE IF EXISTS Addresses CASCADE;
DROP TABLE IF EXISTS Admins CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;

CREATE TABLE Customers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    phone TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Addresses (
    id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES Customers(id) ON DELETE CASCADE,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    country TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE
);

CREATE TABLE Categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT
);

CREATE TABLE Products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL,
    category_id INT REFERENCES Categories(id) ON DELETE SET NULL,
    material TEXT,         -- e.g., Gold, Silver, Platinum
    brand TEXT,            -- e.g., Designer or Brand name
    availability_status BOOLEAN DEFAULT TRUE
);

CREATE TABLE Orders (
    id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES Customers(id) ON DELETE CASCADE,
    address_id INT REFERENCES Addresses(id) ON DELETE CASCADE,
    total_cost NUMERIC(10,2) NOT NULL,
    order_status TEXT DEFAULT 'Pending',
    payment_method TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Order_Details (
    id SERIAL PRIMARY KEY,
    order_id INT REFERENCES Orders(id) ON DELETE CASCADE,
    product_id INT REFERENCES Products(id) ON DELETE CASCADE,
    quantity INT NOT NULL,
    price NUMERIC(10,2) NOT NULL
);

CREATE TABLE Admins (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Liked_Products (
    customer_id INT REFERENCES Customers(id) ON DELETE CASCADE,
    product_id INT REFERENCES Products(id) ON DELETE CASCADE,
    PRIMARY KEY (customer_id, product_id)
);
