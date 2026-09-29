WITH t1 AS (SELECT COUNT(*) AS count_of_customers, customer_unique_id
FROM customers
RIGHT JOIN orders
USING(customer_id)
WHERE order_status='delivered'
GROUP BY customer_unique_id)

SELECT COUNT(*) AS count_of_customers, 
COUNT(count_of_customers) FILTER(WHERE count_of_customers > 1) AS count_of_customers_many_orders,
ROUND(COUNT(count_of_customers) FILTER(WHERE count_of_customers > 1) / COUNT(*)::decimal * 100, 2) AS share_of_repeat_customers
FROM t1;

WITH t2 AS (SELECT customer_unique_id, 
SUM(price) AS total_price, 
COUNT(DISTINCT order_id) AS count_orders,
CASE WHEN COUNT(DISTINCT order_id) = 1 THEN 'Один заказ'
ELSE 'Два и более заказов'
END AS groups
FROM order_items
LEFT JOIN orders
USING(order_id)
LEFT JOIN customers
USING(customer_id)
WHERE order_status='delivered'
GROUP BY customer_unique_id),

t3 AS (SELECT groups,
COUNT(*) AS customers_count,
SUM(total_price) AS sales_amount
FROM t2
GROUP BY groups)

SELECT groups,
customers_count,
sales_amount,
ROUND(sales_amount::decimal / SUM(sales_amount) OVER() * 100,2) AS sales_share,
ROUND(sales_amount:: decimal / customers_count, 2) AS avg_sales_per_customer
FROM t3;

-- 94.49 % всех продаж обеспечивают покупатели, совершившие по одному заказу. Это говорит о том, что повторные покупки делают 
-- здесь редко. -- Покупатели с двумя и более доставленными заказами потратили
-- в среднем 260,05 за период данных — примерно в 1,9 раза больше
-- покупателей с одним заказом (137,96).





