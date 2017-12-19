-- select id from payments where partner_end_user_id = (select partner_end_user_id from payments where id = 53344)
WbVarDef pid='$[?id]';

SELECT *
FROM payments
WHERE (id IN ($[pid]))
-------- or  ((payment_request_body #>> '{email}')  = ' $[pemail]')76962
ORDER BY id DESC;

-- Proc_requests table
-- @wbResult proc_requests
SELECT *
-- pr.id, pr.created_at, pr._updated_at, pr.payment_id, prv.tx_type, prv.status, prv.status_description, prv.masked_credit_card, prv.avs_code, prv.threeds_enrolled
       FROM proc_requests_view AS prv
WHERE prv.payment_id IN ($[pid]);

-- @WbResult pr
SELECT *
FROM proc_requests
WHERE payment_id IN ($[pid]);

--User Browser Events
-- @WbResult ube
SELECT *
FROM user_browser_events
WHERE payment_id IN ($[pid])
ORDER BY payment_id,
         id;

-- Partner end user id
-- @WbResult partner_user
SELECT *
FROM partner_end_users
WHERE id IN (SELECT partner_end_user_id FROM payments WHERE id IN ($[pid]));

-- Verification requests 
-- @WbResult ver_req
SELECT *
FROM verification_requests
WHERE payment_id IN ($[pid]);

-- @WbResult uploads
SELECT *
FROM uploads
WHERE simplex_end_user_id IN (SELECT simplex_end_user_id FROM payments WHERE id IN ($[pid]));

-- Payments log
-- @WbResult payments_log
SELECT *
FROM payments_log
WHERE current_payment_id IN ($[pid]);

-- Decisions 
-- @WbResult decisions
SELECT *
FROM decisions
WHERE payment_id IN ($[pid]);

-- Payments Log
-- @WbResult payment log
SELECT *
FROM payments_log
WHERE current_payment_id IN ($[pid]);

--Comments
-- @WbResult comments
SELECT *
FROM comments
WHERE payment_id IN ($[pid]);

-- @WbResult simplex_end_user
SELECT *
FROM simplex_end_users
WHERE id IN (SELECT simplex_end_user_id FROM payments WHERE id IN ($[pid]));

--@WbResult seu_log
SELECT *
FROM simplex_end_users_log
WHERE current_simplex_user_id IN (SELECT simplex_end_user_id FROM payments WHERE id IN ($[pid]));

--@WbResult peu_log
SELECT *
FROM partner_end_users_log
WHERE current_end_user_id IN (SELECT partner_end_user_id FROM payments WHERE id IN ($[pid]));

--@WbResult phone_ver
SELECT *
FROM phone_verifications
WHERE payment_id IN (SELECT id
                     FROM payments
                     WHERE partner_end_user_id IN (SELECT partner_end_user_id FROM payments WHERE id IN ($[pid])));

--@WbResult cnam
SELECT *
FROM enrich_opencnam
WHERE phone IN (SELECT phone
                FROM phone_verifications
                WHERE payment_id IN (SELECT id
                                     FROM payments
                                     WHERE partner_end_user_id IN (SELECT partner_end_user_id FROM payments WHERE id IN ($[pid]))));
                                     


select * from payments order by 1 desc limit 50;
