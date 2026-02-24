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