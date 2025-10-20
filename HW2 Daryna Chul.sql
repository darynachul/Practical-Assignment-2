DROP DATABASE IF EXISTS home2;
CREATE DATABASE home2;
USE home2;

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
  customer_id INT PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(150),
  region VARCHAR(50),
  signup_date DATE,
  status VARCHAR(20)
);
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  order_id BIGINT PRIMARY KEY,
  customer_id INT,
  order_date DATE,
  status VARCHAR(20),
  payment_method VARCHAR(50)
);
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
  product_id INT,
  product_name VARCHAR(100),
  category VARCHAR(50),
  order_id BIGINT,
  quantity INT,
  price DECIMAL(10,2)
);
Select count(*) from order_items;
Select count(*) from orders;
Select count(*) from customers;
--  NON-OPTIMIZED QUERY 
SELECT 
    c.customer_id,
    c.name,
    c.email,
    SUM(oi.quantity) AS total_products,
    SUM(oi.quantity * oi.price) AS total_payment
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.name, c.email; 


--  OPTIMIZED QUERY
CREATE INDEX idx_order_items_order_id ON order_items(order_id); -- Creation of this index on the order_id column helps to speed up JOIN between tables orders and order_items
CREATE INDEX idx_orders_status ON orders(status); -- Creation of this index on the status column helps to find completed orders fast without scanning all table 

WITH completed_orders AS (
    SELECT o.customer_id, o.order_id
    FROM orders o USE INDEX (idx_orders_status)
    WHERE o.status = 'Completed' -- Creation CTE completed_orders and filtering columns with the status "completed" and using an index for faster searching   
)
SELECT -- It is the main query which selects customer_id, their name and email and counts quantity of good they bought and their total amount for purchase
    c.customer_id, c.name, c.email,
    SUM(oi.quantity) AS total_products,
    SUM(oi.quantity * oi.price) AS total_payment
FROM customers c 
JOIN completed_orders co ON c.customer_id = co.customer_id -- Merge table customers with the completed_orders 
JOIN order_items oi USE INDEX (idx_order_items_order_id) ON co.order_id = oi.order_id -- Merge each completed order with items from order_item using index for faster searching
GROUP BY c.customer_id, c.name, c.email; -- Groups the results based on customer_id, name and email
-- USE INDEX: On the positive side, USE INDEX indicates the correct index, reduces full table scans and helps speed up queries. On the negative side, it can slow down the process if the data changes.


-- EXECUTION PLANS
-- Non-optimized query takes longer to execute because it scans three tables with large amounts of data (full-table scan). Moreover, filtration occurs after JOIN, it's ineffectively as time is spent for unnessesary merging of each row from the tables
-- Optimized query executes faster as it includes indexes(faster scanning), filtration occurs before JOIN in CTE which puts less strain on memory.
--  NON-OPTIMIZED QUERY 
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.name,
    c.email,
    SUM(oi.quantity) AS total_products,
    SUM(oi.quantity * oi.price) AS total_payment
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.name, c.email;
--  OPTIMIZED QUERY
EXPLAIN ANALYZE
WITH completed_orders AS (
    SELECT o.customer_id, o.order_id
    FROM orders o USE INDEX (idx_orders_status)
    WHERE o.status = 'Completed'
)
SELECT 
    c.customer_id, c.name, c.email,
    SUM(oi.quantity) AS total_products,
    SUM(oi.quantity * oi.price) AS total_payment
FROM customers c
JOIN completed_orders co ON c.customer_id = co.customer_id
JOIN order_items oi USE INDEX (idx_order_items_order_id) ON co.order_id = oi.order_id
GROUP BY c.customer_id, c.name, c.email;




