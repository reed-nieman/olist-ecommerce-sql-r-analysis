# ============================================================
# PROJECT 1: CONNECTING R TO POSTGRESQL & PULLING TASK 3 DATA
# ============================================================

# 1. Load the installed packages into memory
library(DBI)
library(RPostgres)
library(tidyverse)

# 2. Establish a connection object to your local PostgreSQL database
con <- dbConnect(
  RPostgres::Postgres(),
  dbname   = "olist_db",
  host     = "localhost",
  port     = 5432,
  user     = "postgres",
  password = "dammerung"  # <--- Change this to your password
)

# 3. Define your SQL query directly as an R text string
sql_query <- "
SELECT 
    c.customer_state,
    COUNT(o.order_id) AS total_delivered_orders,
    ROUND(AVG(EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))), 1) AS avg_delivery_days,
    ROUND(AVG(EXTRACT(DAY FROM (o.order_estimated_delivery_date - o.order_delivered_customer_date))), 1) AS avg_days_ahead_of_estimate
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(o.order_id) >= 500
ORDER BY avg_delivery_days DESC;
"

# 4. Execute the query on PostgreSQL and store the output in an R Data Frame
delivery_data <- dbGetQuery(con, sql_query)

# 5. Inspect the imported data frame in the Console
print(delivery_data)

# 6. Always close the database connection when done
dbDisconnect(con)

# ============================================================
# VISUALIZATION: BAR CHART OF DELIVERY TIMES BY STATE
# ============================================================

ggplot(delivery_data, aes(x = reorder(customer_state, avg_delivery_days), y = avg_delivery_days)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Average Delivery Time by Brazilian State",
    subtitle = "Analysis of delivered orders from Olist E-commerce dataset",
    x = "State",
    y = "Average Delivery Duration (Days)"
  ) +
  theme_minimal()