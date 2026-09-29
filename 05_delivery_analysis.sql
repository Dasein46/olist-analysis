-- Общая статистика опозданий среди доставленных заказов.
-- Опоздание: фактическая дата доставки позже обещанной.
-- Сравниваем календарные даты без учёта времени суток.
-- В знаменатель доли опозданий входят только заказы,
-- у которых заполнены обе даты доставки.
SELECT COUNT(*) AS delivered_orders,
	COUNT(*) FILTER(WHERE order_delivered_customer_date IS NOT NULL 
	AND order_estimated_delivery_date IS NOT NULL) AS orders_filled_dates,
	COUNT(*) FILTER(WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date) AS late_orders,
	ROUND((COUNT(*) FILTER(WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date))::decimal / 
	COUNT(*) FILTER(WHERE order_delivered_customer_date IS NOT NULL 
	AND order_estimated_delivery_date IS NOT NULL) * 100,2) AS share_late_orders
FROM orders
WHERE order_status='delivered';
-- Результат: 96 478 доставленных заказов.
-- Обе даты заполнены у 96 470 заказов.
-- У 8 заказов отсутствует хотя бы одна необходимая дата.
-- Опоздали 6 534 заказа: 6,77% от заказов с обеими датами.

-- Сравнение опозданий по штатам покупателей.
-- Соединяем orders с customers по customer_id.
-- Показываем пять штатов с наибольшим количеством опозданий.
-- share_late_orders: доля опозданий среди заказов
-- данного штата с заполненными обеими датами доставки.
-- avg_days_late: среднее число дней задержки
-- только среди опоздавших заказов данного штата.
-- Доля штата в общем количестве опозданий рассчитывается
-- по всем штатам до ограничения результата через LIMIT.
SELECT customer_state,
orders_filled_dates,
late_orders,
share_late_orders,
avg_days_late,
ROUND(late_orders::decimal / SUM(late_orders) OVER() * 100,2) AS share_pct
FROM
(SELECT customer_state,
COUNT(*) FILTER(WHERE order_delivered_customer_date IS NOT NULL 
AND order_estimated_delivery_date IS NOT NULL) AS orders_filled_dates,
COUNT(*) FILTER(WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date) AS late_orders,
ROUND((COUNT(*) FILTER(WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date))::decimal / 
COUNT(*) FILTER(WHERE order_delivered_customer_date IS NOT NULL 
AND order_estimated_delivery_date IS NOT NULL) * 100,2) AS share_late_orders,
ROUND(AVG(order_delivered_customer_date::date - order_estimated_delivery_date::date) FILTER(
WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date
),2) AS avg_days_late
FROM orders
LEFT JOIN customers
USING(customer_id)
WHERE order_status='delivered'
GROUP BY customer_state) t1
ORDER BY late_orders DESC
LIMIT 5;
-- Результаты:
-- SP: 1 820 опозданий, доля 4,49%, средняя задержка 8,33 дня.
-- RJ: 1 495 опозданий, доля 12,11%, средняя задержка 13,52 дня.
-- BA: 396 опозданий, доля 12,16%, средняя задержка 12,02 дня.
-- Среди пяти штатов с наибольшим количеством опозданий
-- RJ и BA имеют наиболее высокую долю опозданий.
-- SP лидирует по абсолютному количеству опоздавших заказов.
-- Для дальнейшего сравнения по месяцам выбраны RJ, BA и SP:
-- учитываем количество опозданий, их долю и длительность.

-- Анализ опозданий по месяцам в RJ, BA и SP.
-- Месяц определяется по дате покупки заказа.
-- Доля опозданий рассчитана среди доставленных заказов
-- с заполненными фактической и обещанной датами доставки.
SELECT DATE_TRUNC('month', order_purchase_timestamp) AS month,
customer_state,
COUNT(*) FILTER(WHERE order_delivered_customer_date IS NOT NULL 
AND order_estimated_delivery_date IS NOT NULL) AS orders_filled_dates,
COUNT(*) FILTER(WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date) AS late_orders,
ROUND((COUNT(*) FILTER(WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date))::decimal / 
COUNT(*) FILTER(WHERE order_delivered_customer_date IS NOT NULL 
AND order_estimated_delivery_date IS NOT NULL) * 100,2) AS share_late_orders,
ROUND(AVG(order_delivered_customer_date::date - order_estimated_delivery_date::date) FILTER(
WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date
),2) AS avg_days_late
FROM orders
LEFT JOIN customers
USING(customer_id)
WHERE order_status='delivered' AND customer_state IN ('RJ', 'BA', 'SP')
GROUP BY month, customer_state
ORDER BY month, customer_state;
-- Выводы:
-- 1. В RJ выраженное ухудшение наблюдается с ноября 2017
--    по март 2018. В марте доля опозданий достигает 34,49%,
--    а в апреле снижается до 4,83%.
-- 2. В BA особенно высокая доля опозданий наблюдается
--    в феврале–мае 2018. Максимум — 31,49% в марте.
-- 3. SP также имеет заметные всплески:
--    9,42% в марте и 9,01% в августе 2018.
-- 4. В марте 2018 в SP опоздали 280 заказов, в RJ — 298.
--    Поэтому при выборе приоритетов учитываем и долю,
--    и абсолютное количество опоздавших заказов.
-- 5. Причины совпадения мартовских пиков пока не установлены.

-- Подготовка отзывов для анализа доставки: одна строка на заказ.
-- Рассчитываем среднюю оценку по доступным отзывам каждого заказа.
-- При сравнении групп доставки каждый заказ имеет одинаковый вес.
WITH reviews_by_order AS (SELECT order_id,
	AVG(review_score) AS avg_order_score,
	COUNT(*) AS reviews_count
FROM order_reviews
GROUP BY order_id)
-- Результат: 98 673 строки, по одной на каждый заказ с отзывами.
-- avg_order_score: средняя оценка по записям отзывов заказа.
-- reviews_count: количество записей отзывов этого заказа.
-- Заказы без отзывов в этот результат не входят.

-- Сравнение оценок заказов, доставленных в срок и с опозданием.
-- Учитываем только доставленные заказы с обеими датами доставки.
-- Каждый заказ представлен средней оценкой его отзывов.
-- Заказы без оценки учитываем в количестве заказов,
-- но не включаем в расчёт средней оценки.
SELECT CASE WHEN order_delivered_customer_date::date > order_estimated_delivery_date::date THEN 'С опозданием'
		ELSE 'В срок'
		END AS delivery_group,
	COUNT(*) AS orders_count,
	COUNT(avg_order_score) AS orders_with_score,
	ROUND(AVG(avg_order_score), 2) AS avg_review_score
FROM orders
LEFT JOIN reviews_by_order
USING(order_id)
WHERE order_status='delivered'
	AND order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_group;
-- Средняя оценка заказов, доставленных в срок, — 4,29,
-- с опозданием — 2,27. Разница составляет около 2,02 балла.
-- Оценки доступны для 89 443 заказов в срок
-- и 6 381 заказа с опозданием.
-- В этой выборке опоздания связаны с более низкой средней оценкой.
-- Само сравнение не доказывает, что вся разница вызвана опозданием.

-- Сравнение средних оценок по длительности опоздания.
-- Сохраняем одну строку на заказ и прежние условия отбора.
WITH reviews_by_order AS (SELECT order_id,
	AVG(review_score) AS avg_order_score,
	COUNT(*) AS reviews_count
FROM order_reviews
GROUP BY order_id)

SELECT CASE WHEN order_delivered_customer_date::date - order_estimated_delivery_date::date <= 0 THEN 'В срок'
		WHEN order_delivered_customer_date::date - order_estimated_delivery_date::date <= 7 
		AND order_delivered_customer_date::date - order_estimated_delivery_date::date >= 1 THEN 'Опоздание на 1-7 дней'
		WHEN order_delivered_customer_date::date - order_estimated_delivery_date::date <= 14 
		AND order_delivered_customer_date::date - order_estimated_delivery_date::date >= 8 THEN 'Опоздание на 8-14 дней'
		ELSE 'Опоздание на 15 дней и более'
		END AS delivery_group,
	COUNT(*) AS orders_count,
	COUNT(avg_order_score) AS orders_with_score,
	ROUND(AVG(avg_order_score), 2) AS avg_review_score
FROM orders
LEFT JOIN reviews_by_order
USING(order_id)
WHERE order_status='delivered'
	AND order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_group;
-- Средняя оценка составляет 4,29 для доставки в срок
-- и 2,72 для опозданий на 1–7 дней.
-- При задержке на 8–14 дней средняя оценка равна 1,67,
-- на 15 дней и более — 1,73.
-- В обеих группах с задержкой свыше недели оценки остаются низкими.
-- Разница между ними составляет около 0,06 балла.
-- Наблюдаемая связь не доказывает причинное влияние задержки.