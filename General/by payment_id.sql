WbVarDef pid='$[?id]';


-- Payments table 
-- @WbResult payments_full 
SELECT *
FROM payments
WHERE (id IN ($[pid]))
ORDER BY id DESC;


-- @WbResult pr
SELECT *
FROM proc_requests
WHERE payment_id IN ($[pid]);

-- Decisions 
-- @WbResult decisions
SELECT *
FROM decisions
WHERE payment_id IN ($[pid]);


--@WbResult seu
SELECT *
FROM simplex_end_users
WHERE id in (select simplex_end_user_id from payments where id in ($[pid]));


-- Partner end user id
-- @WbResult partner_user
SELECT *
FROM partner_end_users
WHERE id IN (SELECT partner_end_user_id FROM payments WHERE id IN ($[pid]));

-- Partner end user id
-- @WbResult peu_log
SELECT *
FROM partner_end_users_log
WHERE current_end_user_id IN (SELECT partner_end_user_id FROM payments WHERE id IN ($[pid]));

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

--Comments
-- @WbResult comments

SELECT *
FROM comments
WHERE payment_id IN ($[pid]);

--SEU log
--@WbResult seu_log
SELECT *
FROM simplex_end_users_log
WHERE current_simplex_user_id in (select simplex_end_user_id from payments where id in ($[pid]));

--User Browser Events
-- @WbResult ube
SELECT *
FROM user_browser_events
WHERE payment_id IN ($[pid])
ORDER BY payment_id,
         id;
         
--CBs
--@WbResult cb
SELECT *
FROM chargebacks
WHERE payment_id IN ($[pid])
ORDER BY payment_id,
         id;
         
--Refunds
--@WbResult redunds
SELECT *
FROM refunds
WHERE payment_id IN ($[pid])
ORDER BY payment_id,
         id;
         
--Fraud Warnings
--@WbResult fws
SELECT *
FROM fraud_warnings
WHERE payment_id IN ($[pid])
ORDER BY payment_id,
         id;
         
         



