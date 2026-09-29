-- Анализ продаж по категориям
WITH t1 AS (SELECT COALESCE(NULLIF(TRIM(product_category_name), ''), 'Без категории') AS category,
COUNT(DISTINCT order_items.order_id) AS orders_count,
COUNT(order_items.order_id) AS items_count,
SUM(price) AS sales_amount
FROM orders
LEFT JOIN order_items
USING(order_id)
LEFT JOIN products
USING(product_id)
WHERE order_status='delivered'
GROUP BY category
)

SELECT category, 
orders_count, 
items_count, 
sales_amount, 
ROUND(sales_amount / SUM(sales_amount) OVER() * 100,2) AS sales_share_pct,
ROUND(sales_amount / items_count,2) AS avg_item_price
FROM t1
ORDER BY sales_amount DESC
LIMIT 5;

WITH t2 AS(
SELECT DATE_TRUNC('month', order_purchase_timestamp) AS month,
COUNT(DISTINCT order_id) AS orders_count,
SUM(price) AS sales_amount,
ROUND(SUM(price) / COUNT(DISTINCT order_id),2) AS avg_sales
FROM orders
LEFT JOIN order_items
USING(order_id)
WHERE order_status='delivered'
GROUP BY month
ORDER BY month),

t3 AS(
SELECT LAG(sales_amount) OVER(ORDER BY month) AS prev_sales_amount,
LAG(month) OVER(ORDER BY month) AS prev_month,
sales_amount,
month,
orders_count,
avg_sales
FROM t2
)

SELECT month, 
sales_amount,
prev_sales_amount,
orders_count,
avg_sales,
CASE WHEN month=prev_month + INTERVAL '1 month' 
THEN ROUND((sales_amount - prev_sales_amount) / NULLIF(prev_sales_amount,0) * 100,2)
ELSE NULL
END AS sales_mom_pct
FROM t3
ORDER BY month;

-- ноябрь 2017 — месяц с максимальной суммой продаж за 2017 год, 
-- и рост обеспечило увеличение числа заказов. Рост количества заказов 
-- перекрыл снижение средней стоимости заказа.


