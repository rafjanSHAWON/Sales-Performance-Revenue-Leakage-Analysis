
-- Table Design 
-- Create 4 tables( Clean, Normalized, Professional)

DROP TABLE IF EXISTS customers;

CREATE TABLE customers(
    customer_id SERIAL PRIMARY KEY,
    customer_name TEXT,
    signup_date DATE,
    region TEXT
);


DROP TABLE IF EXISTS products ;

CREATE TABLE products(
    product_id SERIAL PRIMARY KEY,
    product_name TEXT,
    category TEXT,
    cost_price NUMERIC(10,2),
    selling_price NUMERIC(10,2)
);


DROP TABLE IF EXISTS orders;

CREATE TABLE orders(
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE,
    payment_method TEXT
);
DROP TABLE IF EXISTS order_items;

CREATE TABLE order_items(
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    discount NUMERIC(5,2)
);


/*  Insert data in customers, products, orders, order_item */

COPY customers
FROM 'F:\Git_Project Star\data\customers.csv'
DELIMITER ',' CSV HEADER;

SELECT * FROM customers;

COPY products
FROM 'F:\Git_Project Star\data\products.csv'
DELIMITER ',' CSV HEADER;

SELECT * FROM products;


COPY orders
FROM 'F:\Git_Project Star\data\orders.csv'
DELIMITER ',' CSV HEADER;

SELECT * FROM orders;


COPY order_items
FROM 'F:\Git_Project Star\data\order_items.csv'
DELIMITER ',' CSV HEADER;

SELECT * FROM order_items;