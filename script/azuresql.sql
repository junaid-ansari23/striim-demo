

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

SELECT count(*) FROM retail.customers AS customers;

SELECT max(customer_id) from retail.customers;

SELECT * FROM retail.customers;

-- Truncate
-- identity & cascade don't work for Azure SQL

-- use this for delete
DELETE FROM retail.order_items;
DELETE FROM retail.orders;
DELETE FROM retail.customers;
DELETE FROM retail.products;
DELETE FROM retail.stores;

-- drop tables
DROP TABLE retail.order_items;
DROP TABLE retail.orders;
DROP TABLE retail.customers;
DROP TABLE retail.products;
DROP TABLE retail.stores;

-- drop schema
DROP SCHEMA retail;
