-- Представление отзывов для Power BI: одна строка на заказ.
-- Используем среднюю оценку всех доступных отзывов заказа.
-- Сохраняем среднюю без округления для последующих расчётов.
CREATE OR REPLACE VIEW public.vw_reviews_by_order AS
SELECT 
	order_id,
	AVG(review_score) AS avg_order_score,
	COUNT(*) AS reviews_count
FROM public.order_reviews
GROUP BY order_id;

-- Просмотр первых десяти строк представления.
SELECT *
FROM public.vw_reviews_by_order
LIMIT 10;

-- Подготовка данных заказов для Power BI.
-- Объединяем сведения о заказе, покупателе и отзывах.
-- Сохраняем все заказы: одна строка на order_id.
CREATE OR REPLACE VIEW public.vw_orders AS
SELECT 
	order_id,
	customer_id,
	order_status,
	order_purchase_timestamp::date AS purchase_date,
	order_delivered_customer_date::date AS delivered_date,
	order_estimated_delivery_date::date AS estimated_delivery_date,
	customer_unique_id,
	customer_state,
	avg_order_score,
	reviews_count
FROM public.orders
LEFT JOIN public.customers
USING(customer_id)
LEFT JOIN public.vw_reviews_by_order
USING(order_id);

-- Проверка количества строк и количества уникальных order_id
-- в созданном представлении
SELECT COUNT(*),
	COUNT(DISTINCT order_id)
FROM public.vw_orders;
-- Оба значения равны 99 441, а значит каждый заказ представлен одной строкой

-- Подготовка данных о товарах в заказах для POWER BI
-- Объединяем сведения о товарах в заказах и отдельно самих товарах.
CREATE OR REPLACE VIEW public.vw_orders_items AS
SELECT 
	order_id,
	order_item_id,
	product_id,
	price,
	freight_value,
	CASE WHEN product_category_name IS NULL OR TRIM(product_category_name)='' THEN 'Без категории'
		ELSE product_category_name
		END AS product_category_name
FROM public.order_items
LEFT JOIN public.products
USING(product_id);

-- Проверка количества строк и отсутствия повторов пары order_id + order_item_id
-- в созданном представлении
SELECT COUNT(*)
FROM public.vw_orders_items;

SELECT COUNT(*), order_id, order_item_id
FROM public.vw_orders_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;
-- Количество строк составляет 112 650, повторы пары order_id + order_item_id отсутствуют