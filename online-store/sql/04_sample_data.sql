INSERT INTO users(name,email,role,password_hash,loyalty_level)
VALUES
    ('Admin','admin@mail.com','admin','hash',1),
    ('Manager','manager@mail.com','manager','hash',0),
    ('Customer','cust@mail.com','customer','hash',0)
    ON CONFLICT (email) DO NOTHING;

INSERT INTO products(name,price,stock_quantity)
VALUES
    ('Laptop',1200.00,10),
    ('Mouse',25.00,100),
    ('Keyboard',55.50,50),
    ('Monitor',230.00,20)
    ON CONFLICT DO NOTHING;
