CREATE OR REPLACE FUNCTION getOrderStatus(p_order_id INT)
RETURNS VARCHAR AS $$
DECLARE
st VARCHAR;
BEGIN
SELECT status INTO st
FROM orders
WHERE order_id = p_order_id;

RETURN st;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION getUserOrderCount()
RETURNS TABLE(user_id INT, order_count INT) AS $$
BEGIN
RETURN QUERY
SELECT u.user_id,
       COUNT(o.order_id)::INT AS order_count
FROM users u
         LEFT JOIN orders o ON o.user_id = u.user_id
GROUP BY u.user_id
ORDER BY u.user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getTotalSpentByUser(p_user_id INT)
RETURNS NUMERIC AS $$
DECLARE
total NUMERIC;
BEGIN
SELECT COALESCE(SUM(total_price), 0)
INTO total
FROM orders
WHERE user_id = p_user_id
  AND status IN ('paid', 'completed');

RETURN total;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION canReturnOrder(p_order_id INT)
RETURNS BOOLEAN AS $$
DECLARE
st VARCHAR;
  dt TIMESTAMP;
BEGIN
SELECT status, order_date
INTO st, dt
FROM orders
WHERE order_id = p_order_id;

IF st IS NULL THEN
    RETURN FALSE;
END IF;

  IF st <> 'completed' THEN
    RETURN FALSE;
END IF;

  IF NOW() - dt > INTERVAL '30 days' THEN
    RETURN FALSE;
END IF;

RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getOrderStatusHistory(p_order_id INT)
RETURNS TABLE(
  history_id INT,
  old_status VARCHAR,
  new_status VARCHAR,
  changed_at TIMESTAMP,
  changed_by INT
) AS $$
BEGIN
RETURN QUERY
SELECT h.history_id,
       h.old_status,
       h.new_status,
       h.changed_at,
       h.changed_by
FROM order_status_history h
WHERE h.order_id = p_order_id
ORDER BY h.changed_at;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getAuditLogByUser(p_user_id INT)
RETURNS TABLE(
  log_id INT,
  entity_type VARCHAR,
  entity_id INT,
  operation VARCHAR,
  performed_at TIMESTAMP,
  details TEXT
) AS $$
BEGIN
RETURN QUERY
SELECT a.log_id,
       a.entity_type,
       a.entity_id,
       a.operation,
       a.performed_at,
       a.details
FROM audit_log a
WHERE a.performed_by = p_user_id
ORDER BY a.performed_at DESC;
END;
$$ LANGUAGE plpgsql;