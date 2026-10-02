-- ============================================================
-- PROJECT 1: OLIST E-COMMERCE DATABASE SETUP SCHEMA
-- ============================================================

-- Drop tables if they already exist to start clean
DROP TABLE IF EXISTS order_payments CASCADE;
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

-- 2. Create Products Table (Independent)
DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

-- 3. Create Orders Table (Depends on customers)
DROP TABLE IF EXISTS orders CASCADE;

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES customers(customer_id),
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- 4. Create Order Items Table (Depends on orders and products)
DROP TABLE IF EXISTS order_items CASCADE;

CREATE TABLE order_items (
    order_id VARCHAR(50) REFERENCES orders(order_id),
    order_item_id INTEGER,
    product_id VARCHAR(50) REFERENCES products(product_id),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10, 2),
    freight_value NUMERIC(10, 2),
    PRIMARY KEY (order_id, order_item_id)
);

-- 5. Create Order Payments Table (Depends on orders)
DROP TABLE IF EXISTS order_payments CASCADE;

CREATE TABLE order_payments (
    order_id VARCHAR(50) REFERENCES orders(order_id),
    payment_sequential INTEGER,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value NUMERIC(10, 2)
);

-- ============================================================
-- VERIFICATION QUERY: CHECK ROW COUNTS ACROSS ALL 5 TABLES
-- ============================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments;

-- ============================================================
-- Task 2 introduces a key e-commerce metric: Average Order Value (AOV)
-- ============================================================

SELECT 
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(op.payment_value), 2) AS total_state_revenue,
    ROUND(SUM(op.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_state_revenue DESC
LIMIT 10;

-- ============================================================
-- Task 3: Delivery Speed vs. Customer Experience (Date Metrics)
-- ============================================================

SELECT 
    c.customer_state,
    COUNT(o.order_id) AS total_delivered_orders,
    -- Calculate average actual shipping duration in days
    ROUND(AVG(EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))), 1) AS avg_delivery_days,
    -- Calculate average delivery gap relative to estimated delivery date
    ROUND(AVG(EXTRACT(DAY FROM (o.order_estimated_delivery_date - o.order_delivered_customer_date))), 1) AS avg_days_ahead_of_estimate
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(o.order_id) >= 500
ORDER BY avg_delivery_days DESC;