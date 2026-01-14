CREATE OR REPLACE PROCEDURE createOrder(
  p_user_id INT,
  p_product_ids INT[],
  p_quantities INT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
new_order_id INT;
  i INT;
  p_price NUMERIC;
  p_stock INT;
  total NUMERIC := 0;
BEGIN
  IF array_length(p_product_ids,1) IS NULL OR array_length(p_quantities,1) IS NULL THEN
    RAISE EXCEPTION 'Empty product list';
END IF;

  IF array_length(p_product_ids,1) <> array_length(p_quantities,1) THEN
    RAISE EXCEPTION 'Array lengths mismatch';
END IF;

  -- создаём заказ
INSERT INTO orders(user_id, status, total_price)
VALUES (p_user_id, 'pending', 0)
    RETURNING order_id INTO new_order_id;

-- добавляем позиции
FOR i IN 1..array_length(p_product_ids,1) LOOP
SELECT price, stock_quantity
INTO p_price, p_stock
FROM products
WHERE product_id = p_product_ids[i];

IF p_price IS NULL THEN
      RAISE EXCEPTION 'Product not found: %', p_product_ids[i];
END IF;

    IF p_stock < p_quantities[i] THEN
      RAISE EXCEPTION 'Not enough stock for product_id=% (need %, have %)',
        p_product_ids[i], p_quantities[i], p_stock;
END IF;

UPDATE products
SET stock_quantity = stock_quantity - p_quantities[i]
WHERE product_id = p_product_ids[i];

INSERT INTO order_items(order_id, product_id, quantity, price)
VALUES (new_order_id, p_product_ids[i], p_quantities[i], p_price);

total := total + (p_price * p_quantities[i]);
END LOOP;

UPDATE orders
SET total_price = total
WHERE order_id = new_order_id;

INSERT INTO audit_log(entity_type, entity_id, operation, performed_by, details)
VALUES ('order', new_order_id, 'insert', p_user_id, 'Order created');
END;
$$;



CREATE OR REPLACE PROCEDURE updateOrderStatus(
  p_order_id INT,
  p_new_status VARCHAR,
  p_changed_by INT
)
LANGUAGE plpgsql
AS $$
DECLARE
oldst VARCHAR;
BEGIN
SELECT status INTO oldst
FROM orders
WHERE order_id = p_order_id;

IF oldst IS NULL THEN
    RAISE EXCEPTION 'Order not found: %', p_order_id;
END IF;

UPDATE orders
SET status = p_new_status
WHERE order_id = p_order_id;

INSERT INTO order_status_history(order_id, old_status, new_status, changed_by)
VALUES (p_order_id, oldst, p_new_status, p_changed_by);


INSERT INTO audit_log(entity_type, entity_id, operation, performed_by, details)
VALUES ('order', p_order_id, 'update', p_changed_by, 'Status changed: '||oldst||' -> '||p_new_status);
END;
$$;
