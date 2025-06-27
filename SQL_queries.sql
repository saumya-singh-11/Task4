USE sql_invoicing;

-- =========================================
-- a. Use SELECT, WHERE, ORDER BY, GROUP BY
-- =========================================

SELECT 
    state,
    COUNT(*) AS client_count,
    AVG(CHAR_LENGTH(name)) AS avg_name_length,
    MAX(CHAR_LENGTH(name)) AS longest_name_length,
    MIN(city) AS first_city
FROM clients
WHERE state IS NOT NULL
GROUP BY state
HAVING AVG(CHAR_LENGTH(name)) > 6
ORDER BY client_count DESC;

-- ===============================
-- b. Use JOINS (INNER, LEFT)
-- ===============================

SELECT 
    c.name AS client_name,
    i.number AS invoice_number,
    i.invoice_total,
    p.amount AS payment_amount,
    pm.name AS payment_method
FROM clients c
INNER JOIN invoices i ON c.client_id = i.client_id
LEFT JOIN payments p ON i.invoice_id = p.invoice_id
LEFT JOIN payment_methods pm ON p.payment_method = pm.payment_method_id
ORDER BY c.name, i.number;

-- ===============================
-- c. Write Subqueries
-- ===============================

-- Clients who paid more than the average total payment
SELECT 
    c.name, cp.total_paid
FROM clients c
JOIN (
    SELECT client_id, SUM(amount) AS total_paid
    FROM payments
    GROUP BY client_id
    HAVING SUM(amount) > (
        SELECT AVG(total_client_payment)
        FROM (
            SELECT client_id, SUM(amount) AS total_client_payment
            FROM payments
            GROUP BY client_id
        ) AS client_totals
    )
) AS cp ON c.client_id = cp.client_id;

-- ===============================
-- d. Aggregate Functions (SUM, AVG)
-- ===============================

-- Total invoice amount per client
SELECT 
    c.name AS client_name,
    SUM(i.invoice_total) AS total_invoiced
FROM clients c
JOIN invoices i ON c.client_id = i.client_id
GROUP BY c.client_id;

-- Average invoice value
SELECT 
    AVG(invoice_total) AS avg_invoice_value
FROM invoices;

-- Client with the highest total payment
SELECT 
    c.name,
    SUM(p.amount) AS total_paid
FROM clients c
JOIN payments p ON c.client_id = p.client_id
GROUP BY c.client_id
ORDER BY total_paid DESC
LIMIT 1;

-- Earliest and latest invoice dates
SELECT 
    MIN(invoice_date) AS earliest_invoice,
    MAX(invoice_date) AS latest_invoice
FROM invoices;

-- Count of invoices per client
SELECT 
    c.name AS client_name,
    COUNT(i.invoice_id) AS invoice_count
FROM clients c
LEFT JOIN invoices i ON c.client_id = i.client_id
GROUP BY c.client_id;

-- Total payments by payment method
SELECT 
    pm.name AS payment_method,
    COUNT(p.payment_id) AS number_of_payments,
    SUM(p.amount) AS total_collected
FROM payments p
JOIN payment_methods pm ON p.payment_method = pm.payment_method_id
GROUP BY p.payment_method;

-- ===============================
-- e. Create Views for Analysis
-- ===============================

CREATE OR REPLACE VIEW v3_client_invoice_totals AS
SELECT 
    c.client_id,
    c.name AS client_name,
    SUM(i.invoice_total) AS total_invoiced,
    COUNT(i.invoice_id) AS invoice_count
FROM clients c
JOIN invoices i ON c.client_id = i.client_id
GROUP BY c.client_id, c.name;

CREATE OR REPLACE VIEW v3_client_payment_totals AS
SELECT 
    c.client_id,
    c.name AS client_name,
    SUM(p.amount) AS total_paid,
    COUNT(p.payment_id) AS num_payments
FROM clients c
JOIN payments p ON c.client_id = p.client_id
GROUP BY c.client_id, c.name;

CREATE OR REPLACE VIEW v3_invoice_status AS
SELECT 
    i.invoice_id,
    i.number AS invoice_number,
    c.name AS client_name,
    i.invoice_total,
    i.payment_total,
    CASE 
        WHEN i.payment_total >= i.invoice_total THEN 'Paid'
        WHEN i.payment_total = 0 THEN 'Unpaid'
        ELSE 'Partial'
    END AS payment_status
FROM invoices i
JOIN clients c ON i.client_id = c.client_id;

CREATE OR REPLACE VIEW v3_payments_by_method AS
SELECT 
    pm.name AS payment_method,
    COUNT(p.payment_id) AS number_of_payments,
    SUM(p.amount) AS total_collected
FROM payments p
JOIN payment_methods pm ON p.payment_method = pm.payment_method_id
GROUP BY p.payment_method;

CREATE OR REPLACE VIEW v3_clients_with_no_payments AS
SELECT 
    c.client_id,
    c.name
FROM clients c
LEFT JOIN payments p ON c.client_id = p.client_id
WHERE p.payment_id IS NULL;

-- ===============================
-- f. Optimize Queries with Indexes
-- (Only on columns not already indexed)
-- ===============================

CREATE INDEX idx_invoice_date_final ON invoices(invoice_date);
CREATE INDEX idx_invoice_total_final ON invoices(invoice_total);
CREATE INDEX idx_clients_city_final ON clients(city);
CREATE INDEX idx_clients_state_final ON clients(state);
CREATE INDEX idx_payments_date_final ON payments(date);

-- ===============================
-- View Indexes
-- ===============================

SHOW INDEXES FROM invoices;
SHOW INDEXES FROM payments;
SHOW INDEXES FROM clients;
