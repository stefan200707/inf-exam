CREATE OR REPLACE FUNCTION trg_update_order_date()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    NEW.order_date := NOW();
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS t_update_order_date ON orders;
CREATE TRIGGER t_update_order_date
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION trg_update_order_date();



CREATE OR REPLACE FUNCTION trg_recalc_total_price_on_product_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.price IS DISTINCT FROM OLD.price THEN

UPDATE orders o
SET total_price = (
    SELECT COALESCE(SUM(oi.quantity * p.price), 0)
    FROM order_items oi
             JOIN products p ON p.product_id = oi.product_id
    WHERE oi.order_id = o.order_id
)
WHERE o.order_id IN (
    SELECT DISTINCT order_id
    FROM order_items
    WHERE product_id = NEW.product_id
);

INSERT INTO audit_log(entity_type, entity_id, operation, details)
VALUES ('product', NEW.product_id, 'update', 'Product price changed -> orders recalculated');

END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS t_recalc_total_price ON products;
CREATE TRIGGER t_recalc_total_price
    AFTER UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION trg_recalc_total_price_on_product_update();



CREATE OR REPLACE FUNCTION trg_order_status_history()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO order_status_history(order_id, old_status, new_status, changed_by)
    VALUES (NEW.order_id, OLD.status, NEW.status, NULL);
END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS t_order_status_history ON orders;
CREATE TRIGGER t_order_status_history
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION trg_order_status_history();
