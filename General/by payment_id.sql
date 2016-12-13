WbVarDef pid='$[?id]';

------WbVarDef pemail = @"SELECT payment_request_body #>> '{email}' FROM payments WHERE id IN ($[pid])";
-- Payments table 
-- @WbResult payments_full 
SELECT *
FROM payments
WHERE (id IN ($[pid]))
-------- or  ((payment_request_body #>> '{email}')  = ' $[pemail]')
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

--@WbResult seu
SELECT *
FROM simplex_end_users
WHERE id in (select simplex_end_user_id from payments where id in ($[pid]));

--@WnResult seu_log
SELECT *
FROM simplex_end_users_log
WHERE current_simplex_user_id in (select simplex_end_user_id from payments where id in ($[pid]));


