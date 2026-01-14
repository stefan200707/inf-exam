CREATE TABLE IF NOT EXISTS users (
                                     user_id SERIAL PRIMARY KEY,
                                     name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin','manager','customer')),
    password_hash VARCHAR(255) NOT NULL,
    loyalty_level INT NOT NULL DEFAULT 0 CHECK (loyalty_level IN (0,1))
    );


CREATE TABLE IF NOT EXISTS products (
                                        product_id SERIAL PRIMARY KEY,
                                        name VARCHAR(150) NOT NULL,
    price NUMERIC(12,2) NOT NULL CHECK (price > 0),
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0)
    );


CREATE TABLE IF NOT EXISTS orders (
                                      order_id SERIAL PRIMARY KEY,
                                      user_id INT NOT NULL REFERENCES users(user_id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending','paid','completed','canceled','returned')),
    total_price NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_price >= 0),
    order_date TIMESTAMP NOT NULL DEFAULT NOW()
    );


CREATE TABLE IF NOT EXISTS order_items (
                                           order_item_id SERIAL PRIMARY KEY,
                                           order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(product_id),
    quantity INT NOT NULL CHECK(quantity > 0),
    price NUMERIC(12,2) NOT NULL CHECK(price > 0)
    );


CREATE TABLE IF NOT EXISTS order_status_history (
                                                    history_id SERIAL PRIMARY KEY,
                                                    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    changed_by INT REFERENCES users(user_id)
    );


CREATE TABLE IF NOT EXISTS audit_log (
                                         log_id SERIAL PRIMARY KEY,
                                         entity_type VARCHAR(20) NOT NULL CHECK(entity_type IN ('order','product','user','payment')),
    entity_id INT NOT NULL,
    operation VARCHAR(20) NOT NULL CHECK(operation IN ('insert','update','delete','error','info')),
    performed_by INT REFERENCES users(user_id),
    performed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    details TEXT
    );


CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_history_order_id ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_audit_performed_by ON audit_log(performed_by);
