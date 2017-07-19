WbVarDef pid='$[?id]';

-- Payments table
-- @WbResult payment_events_full
SELECT *
FROM payments
WHERE (id IN ($[pid]))
ORDER BY id DESC;

--@WbResult buyer emailage
SELECT *
FROM enrich_email_age
WHERE email IN (SELECT email FROM payments WHERE id IN ($[pid]));


--@WbResult buyer pipl
SELECT *
FROM enrich_pipl
WHERE email IN (SELECT email FROM payments WHERE id IN ($[pid]));

--@WbResult buyer maxmind
WITH buyer_data
AS
(SELECT *
FROM payments
WHERE id IN (($[pid]))) SELECT*FROM enrich_maxmind WHERE request_data ->> 'i' IN (SELECT COALESCE((simplex_login #>> '{ip}'),(partner_login #>> '{ip}'))
                                                                                  FROM buyer_data) AND request_data ->> 'shipAddr' IN (SELECT address1 FROM buyer_data);

--@WbResult buyer blocked
WITH buyer_data
AS
(SELECT *
FROM payments
WHERE id IN (($[pid]))) SELECT*FROM enrich_blocked WHERE ip IN (SELECT COALESCE((simplex_login #>> '{ip}'),(partner_login #>> '{ip}'))
                                                                FROM buyer_data);

--@WbResult buyer whitepages
WITH buyer_data
AS
(SELECT *
FROM payments
WHERE id IN (($[pid]))) 
SELECT*FROM enrich_whitepages_v3 WHERE request_data ->> 'ip_address' IN 
(SELECT COALESCE((simplex_login #>> '{ip}'),(partner_login #>> '{ip}'))
FROM buyer_data) AND request_data ->> 'firstname' IN (SELECT first_name FROM buyer_data);

--@WbResult buyer cnam
WITH buyer_data
AS
(SELECT *
FROM payments
WHERE id IN (($[pid])))
 SELECT*FROM enrich_opencnam WHERE phone IN (SELECT phone FROM buyer_data);


