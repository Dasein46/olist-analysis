-- Проверка данных

-- Проверка количества покупателей и уникальности идентификаторов
SELECT COUNT(*), 
	COUNT(DISTINCT(customer_id)), 
	COUNT(DISTINCT(customer_unique_id))
FROM customers;
-- Результат: 99 441 строка, 99 441 уникальный customer_id,
-- 96 096 уникальных customer_unique_id.

-- Проверка пропусков в customer_unique_id:
-- учитываем NULL, пустые строки и строки из пробелов.
SELECT COUNT(*)
FROM customers
WHERE customer_unique_id IS NULL OR TRIM(customer_unique_id) = '';
-- Результат: пропусков не найдено.

-- Проверка количества заказов и уникальности order_id.
SELECT COUNT(*), 
	COUNT(DISTINCT order_id)
FROM orders;
-- Результат: 99 441 строка и 99 441 уникальный order_id.
-- Каждый заказ представлен одной строкой.

-- Проверка связи orders с customers по customer_id.
-- Ищем заказы, для которых отсутствует запись покупателя.
SELECT COUNT(DISTINCT order_id)
FROM orders
LEFT JOIN
customers
USING(customer_id)
WHERE customers.customer_id IS NULL;
-- Результат: таких заказов не найдено.

-- Проверка количества товарных позиций и представленных заказов.
SELECT COUNT(*), 
	COUNT(DISTINCT order_id)
FROM order_items;
-- Результат: 112 650 позиций в 98 666 заказах.
-- Несколько позиций в одном заказе допустимы.

-- Поиск повторяющихся пар (order_id, order_item_id).
-- Эта пара должна однозначно определять позицию внутри заказа.
SELECT order_id, 
	order_item_id
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1
LIMIT 10;
-- Результат: повторяющихся пар не найдено.

-- Проверка количества товаров и уникальности product_id.
SELECT COUNT(*), 
	COUNT(DISTINCT product_id)
	FROM products;
-- Результат: 32 951 строка и 32 951 уникальный product_id.

-- Проверка пропусков в product_category_name.
SELECT COUNT(product_id) 
FROM products
WHERE product_category_name IS NULL OR TRIM(product_category_name) = '';
-- Результат: 610 товаров без заполненной категории.
-- В анализе сохраняем эти товары в группе «Без категории».

-- Проверка количества отзывов и уникальности идентификаторов
SELECT COUNT(*), 
	COUNT(DISTINCT review_id), 
	COUNT(DISTINCT order_id)
FROM order_reviews;
-- Результат: 99 224 строки, 98 410 уникальных review_id,
-- 98 673 уникальных order_id.

-- Проверка пропусков в идентификаторах отзывов и заказов,
-- а также отсутствующих оценок и оценок вне диапазона 1–5.
SELECT COUNT(*) FILTER(WHERE review_id IS NULL OR TRIM(review_id)='') AS missing_review_id,
	COUNT(*) FILTER(WHERE order_id  IS NULL OR TRIM(order_id)='') AS missing_order_id,
	COUNT(*) FILTER(WHERE review_score IS NULL OR review_score < 1 OR review_score > 5) AS invalid_review_score
FROM order_reviews;
-- Результат: пропусков и аномальных оценок не найдено.

-- Поиск заказов с несколькими отзывами.
-- Сравниваем минимальную и максимальную оценки внутри заказа.
SELECT order_id,
	COUNT(*) AS reviews_count,
	MIN(review_score) AS min_score,
	MAX(review_score) AS max_score
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY reviews_count DESC
LIMIT 10;
-- Найдены заказы с несколькими записями об отзывах.
-- В отдельных заказах оценки различаются.

-- Просмотр оценок и дат отзывов для одного заказа с повторениями.
SELECT order_id,
	review_id,
	review_score,
	review_creation_date,
	review_answer_timestamp
FROM order_reviews
WHERE order_id='c88b1d1b157a9999ce368f218a407141'
ORDER BY review_answer_timestamp;
-- У выбранного заказа три записи, все ответы даны 26 июля 2017 года.