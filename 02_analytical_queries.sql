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