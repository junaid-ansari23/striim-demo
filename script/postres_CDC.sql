
-- INSERT to  customers table to trigger CDC
INSERT INTO retail.customers (full_name, email, city)
VALUES ('John Demo','john.demo@retaildemo.com','New York');

-- Use these for CDC events
INSERT INTO retail.customers (full_name, email, city)
SELECT
    'Customer_' || g,
    'customer_' || g || '@retaildemo.com',
    (ARRAY['New York','Los Angeles','Chicago','Houston','Phoenix'])[floor(random()*5)+1]
FROM generate_series(1,100) g;

delete from retail.customers where customer_id >2000;

select count(*) from retail.customers;

select max(customer_id) from retail.customers;

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