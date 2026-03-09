-- =====================================================
-- Retail Demo - Initial Load Script
-- Database: demo
-- Schema: retail
-- =====================================================

-- 1️.Create schema if not exists
CREATE SCHEMA IF NOT EXISTS retail;

-- Optional but recommended
SET search_path TO retail;

--2.Drop tables in correct order (schema-qualified)
DROP TABLE IF EXISTS retail.order_items;
DROP TABLE IF EXISTS retail.orders;
DROP TABLE IF EXISTS retail.customers;
DROP TABLE IF EXISTS retail.products;
DROP TABLE IF EXISTS retail.stores;

-- =============================
-- TABLE CREATION
-- =============================

CREATE TABLE retail.customers (
                                  customer_id SERIAL PRIMARY KEY,
                                  full_name VARCHAR(100),
                                  email VARCHAR(100),
                                  city VARCHAR(50),
                                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE retail.products (
                                 product_id SERIAL PRIMARY KEY,
                                 product_name VARCHAR(100),
                                 category VARCHAR(50),
                                 price NUMERIC(10,2),
                                 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE retail.stores (
                               store_id SERIAL PRIMARY KEY,
                               store_name VARCHAR(100),
                               city VARCHAR(50),
                               state VARCHAR(50),
                               created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE retail.orders (
                               order_id SERIAL PRIMARY KEY,
                               customer_id INT REFERENCES retail.customers(customer_id),
                               store_id INT REFERENCES retail.stores(store_id),
                               order_date TIMESTAMP,
                               total_amount NUMERIC(10,2)
);

CREATE TABLE retail.order_items (
                                    order_item_id SERIAL PRIMARY KEY,
                                    order_id INT REFERENCES retail.orders(order_id),
                                    product_id INT REFERENCES retail.products(product_id),
                                    quantity INT,
                                    price NUMERIC(10,2)
);

-- =============================
-- DATA POPULATION
-- =============================

INSERT INTO retail.customers (full_name, email, city)
SELECT
    'Customer_' || g,
    'customer_' || g || '@retaildemo.com',
    (ARRAY['New York','Los Angeles','Chicago','Houston','Phoenix'])[floor(random()*5)+1]
FROM generate_series(1,2000) g;

INSERT INTO retail.products (product_name, category, price)
SELECT
    'Product_' || g,
    (ARRAY['Electronics','Clothing','Home','Sports','Beauty'])[floor(random()*5)+1],
    round((random()*500 + 10)::numeric, 2)
FROM generate_series(1,1000) g;

INSERT INTO retail.stores (store_name, city, state)
SELECT
    'Store_' || g,
    (ARRAY['New York','Los Angeles','Chicago','Houston','Phoenix'])[floor(random()*5)+1],
    (ARRAY['NY','CA','IL','TX','AZ'])[floor(random()*5)+1]
FROM generate_series(1,100) g;

INSERT INTO retail.orders (customer_id, store_id, order_date, total_amount)
SELECT
    floor(random()*2000 + 1)::int,
    floor(random()*100 + 1)::int,
    NOW() - (random()*365 || ' days')::interval,
    round((random()*1000 + 50)::numeric, 2)
FROM generate_series(1,5000);

INSERT INTO retail.order_items (order_id, product_id, quantity, price)
SELECT
    o.order_id,
    floor(random() * (SELECT max(product_id) FROM retail.products) + 1)::int,
    floor(random()*5 + 1)::int,
    round((random()*500 + 10)::numeric, 2)
FROM retail.orders o
ORDER BY random()
    LIMIT 5000;

-- =============================
-- SUMMARY
-- =============================

WITH counts AS (
    SELECT
        (SELECT count(*) FROM retail.customers) AS customers,
        (SELECT count(*) FROM retail.products) AS products,
        (SELECT count(*) FROM retail.stores) AS stores,
        (SELECT count(*) FROM retail.orders) AS orders,
        (SELECT count(*) FROM retail.order_items) AS order_items
)
SELECT
    customers,
    products,
    stores,
    orders,
    order_items,
    customers + products + stores + orders + order_items AS total_records
FROM counts;

SELECT
    (SELECT count(*) FROM retail.customers) AS customers,
    (SELECT count(*) FROM retail.products) AS products,
    (SELECT count(*) FROM retail.stores) AS stores,
    (SELECT count(*) FROM retail.orders) AS orders,
    (SELECT count(*) FROM retail.order_items) AS order_items;

-- =====================================================
-- Retail Demo - Truncate Script
-- Clears all data and resets identity sequences
-- =====================================================

TRUNCATE TABLE
    retail.order_items,
    retail.orders,
    retail.customers,
    retail.products,
    retail.stores
RESTART IDENTITY CASCADE;