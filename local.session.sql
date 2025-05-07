
CREATE TABLE users (
    id SERIAL,
    username VARCHAR(100),
    email VARCHAR(255),
    registration_date TIMESTAMP,
    last_login TIMESTAMP,
    status VARCHAR(50),
    bio TEXT,
    metadata JSONB
);

CREATE TABLE orders (
    id SERIAL,
    user_id INT,
    order_date TIMESTAMP,
    amount DECIMAL(10,2),
    status VARCHAR(50),
    shipping_address TEXT,
    billing_address TEXT,
    notes TEXT
);

CREATE TABLE products (
    id SERIAL,
    name VARCHAR(200),
    description TEXT,
    price DECIMAL(10,2),
    category_id INT,
    stock_quantity INT,
    created_at TIMESTAMP
);

CREATE TABLE order_items (
    id SERIAL,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2)
);

CREATE TABLE categories (
    id SERIAL,
    name VARCHAR(100),
    description TEXT,
    parent_id INT
);

-- Добавление индексов
-- Основные индексы для первичных ключей (должны быть по умолчанию)
ALTER TABLE users ADD PRIMARY KEY (id);
ALTER TABLE orders ADD PRIMARY KEY (id);
ALTER TABLE products ADD PRIMARY KEY (id);
ALTER TABLE order_items ADD PRIMARY KEY (id);
ALTER TABLE categories ADD PRIMARY KEY (id);

-- Индексы для внешних ключей
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_products_category_id ON products(category_id);

-- Индексы для часто используемых условий WHERE
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_order_date ON orders(order_date);


-- Заполняем таблицы данными

INSERT INTO users (username, email, registration_date, last_login, status, bio)
SELECT 
    'user_' || i,
    'user_' || i || '@example.com',
    NOW() - (random() * 365 * 10 * INTERVAL '1 day'),
    NOW() - (random() * 30 * INTERVAL '1 day'),
    CASE WHEN random() > 0.5 THEN 'active' ELSE 'inactive' END,
    'This is a bio for user ' || i || '. ' || repeat('text ', 50)
FROM generate_series(1, 100000) i;

INSERT INTO categories (name, description, parent_id)
SELECT 
    'Category ' || i,
    'Description for category ' || i,
    CASE WHEN i % 5 = 0 THEN NULL ELSE (i % 10) + 1 END
FROM generate_series(1, 50) i;

INSERT INTO products (name, description, price, category_id, stock_quantity, created_at)
SELECT 
    'Product ' || i,
    'Detailed description for product ' || i || '. ' || repeat('feature ', 20),
    (random() * 1000)::DECIMAL(10,2),
    (random() * 50)::INT + 1,
    (random() * 1000)::INT,
    NOW() - (random() * 365 * 3 * INTERVAL '1 day')
FROM generate_series(1, 10000) i;

INSERT INTO orders (user_id, order_date, amount, status, shipping_address, billing_address, notes)
SELECT 
    (random() * 100000)::INT + 1,
    NOW() - (random() * 365 * 2 * INTERVAL '1 day'),
    (random() * 1000)::DECIMAL(10,2),
    CASE 
        WHEN random() > 0.8 THEN 'completed'
        WHEN random() > 0.6 THEN 'shipped'
        WHEN random() > 0.4 THEN 'processing'
        ELSE 'pending'
    END,
    'Shipping address for order ' || i,
    'Billing address for order ' || i,
    'Some notes about order ' || i
FROM generate_series(1, 500000) i;

INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT 
    (random() * 500000)::INT + 1,
    (random() * 10000)::INT + 1,
    (random() * 10)::INT + 1,
    (random() * 1000)::DECIMAL(10,2)
FROM generate_series(1, 1000000) i;



-- Запрос 1: явный выбор полей с оптимизированным JOIN
EXPLAIN ANALYZE
SELECT u.username, o.order_date, o.amount, p.name
FROM users u
JOIN orders o ON u.id = o.user_id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE u.id = 123;


-- Запрос 2: выборочное сканирование с учетом индексов
EXPLAIN ANALYZE
SELECT id, user_id, order_date, amount FROM orders WHERE status = 'completed';



-- Запрос 3: проверка производиельности INSERT с индексами
EXPLAIN ANALYZE
INSERT INTO orders (user_id, order_date, amount, status)
VALUES (123, NOW(), 100.00, 'pending');

-- Запрос 4: проверка производиельности UPDATE с индексами
EXPLAIN ANALYZE
UPDATE orders SET amount = 150.00 WHERE id = 1000;

