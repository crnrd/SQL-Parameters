-- Payments table
-- @WbResult payments_full
SELECT *
FROM payments
WHERE (id IN (:p_ids))
ORDER BY id DESC;


-- @WbResult pr
SELECT *
FROM proc_requests
WHERE payment_id IN (:p_ids);

-- Decisions
-- @WbResult decisions
SELECT *
FROM decisions
WHERE payment_id IN (:p_ids);


--@WbResult seu
-- SELECT *
-- FROM simplex_end_users
-- WHERE id in (select simplex_end_user_id from payments where id in (:p_ids));


-- Partner end user id
-- @WbResult partner_user
SELECT *
FROM partner_end_users
WHERE id IN (SELECT partner_end_user_id FROM payments WHERE id IN (:p_ids));

--Partner end user log
-- @WbResult peu_log
SELECT *
FROM partner_end_users_log
WHERE current_end_user_id IN (SELECT partner_end_user_id FROM payments WHERE id IN (:p_ids));

-- Verification requests
-- @WbResult ver_req
SELECT *
FROM verification_requests
WHERE payment_id IN (:p_ids);

SELECT *
FROM verifications
WHERE initial_payment_id IN (:p_ids);

1531540
-- @WbResult uploads
-- SELECT *
-- FROM uploads
-- WHERE simplex_end_user_id IN (SELECT simplex_end_user_id FROM payments WHERE id IN (:p_ids));

-- Payments log
-- @WbResult payments_log
SELECT *
FROM payments_log
WHERE current_payment_id IN (:p_ids);

--Comments
-- @WbResult comments

SELECT *
FROM comments
WHERE payment_id IN (:p_ids);

--SEU log
--@WbResult seu_log
-- SELECT *
-- FROM simplex_end_users_log
-- WHERE current_simplex_user_id in (select simplex_end_user_id from payments where id in (:p_ids));

-- User Browser Events
-- @WbResult ube
SELECT *
FROM user_browser_events
WHERE payment_id IN (:p_ids)
ORDER BY payment_id,
         id;

--CBs
--@WbResult cb
-- SELECT *
-- FROM chargebacks
-- WHERE payment_id IN (:p_ids)
-- ORDER BY payment_id,
--          id;
--
-- --Refunds
-- --@WbResult redunds
-- SELECT *
-- FROM refunds
-- WHERE payment_id IN (:p_ids)
-- ORDER BY payment_id,
--          id;

--Fraud Warnings
--@WbResult fws
-- SELECT *
-- FROM fraud_warnings
-- WHERE payment_id IN (:p_ids)
-- ORDER BY payment_id,
--          id;

-- phone verifications
select *
FROM phone_verifications
where payment_id in (:p_ids);

select * from partner_end_users where id = 16443;
select * from payments where partner_end_user_id = 16443;
select * from payments_log where partner_end_user_id= 16443;


select * from r_payment_events order by 1 desc limit 50;