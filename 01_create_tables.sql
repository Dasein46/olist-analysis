-- Создание таблиц

-- Информация о пользлвателях
CREATE TABLE customers (
	customer_id text,
	customer_unique_id text,
	customer_zip_code_prefix text,
	customer_city text,
	customer_state text
);

-- Информация о заказах
CREATE TABLE orders(
	order_id text,
	customer_id text,
	order_status text,
	order_purchase_timestamp timestamp,
	order_approved_at timestamp,
	order_delivered_carrier_date timestamp,
	order_delivered_customer_date timestamp,
	order_estimated_delivery_date timestamp
);

-- Товары в заказах
CREATE TABLE order_items(
	order_id text,
	order_item_id integer,
	product_id text, 
	seller_id text,
	shipping_limit_date timestamp,
	price numeric(10,2),
	freight_value numeric(10,2)
);

-- Информация о продуктах
CREATE TABLE products (
	product_id text,
	product_category_name text,
	product_name_lenght integer,
	product_description_lenght integer, 
	product_photos_qty integer,
	product_weight_g integer,
	product_length_cm integer,
	product_height_cm integer,
	product_width_cm integer);

-- Отзывы покупателей
CREATE TABLE order_reviews (
    review_id text,
    order_id text,
    review_score integer,
    review_comment_title text,
    review_comment_message text,
    review_creation_date timestamp,
    review_answer_timestamp timestamp
);