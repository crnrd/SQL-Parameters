WbVarDef pid='$[?id]';




-- 
-- -- @WbResult payoneer_full_history
-- SELECT *
-- FROM payoneer_full_history
-- WHERE payment_id  in (select partner_order_id::int from r_payments where id IN ($[pid]))
-- ORDER BY 1 DESC;--


-- -- Payments table
-- @WbResult payment_events_full
SELECT *
FROM r_payment_events
WHERE (payment_id IN ($[pid]))

ORDER BY id DESC;


-- @WbResult r_payments
SELECT *
FROM r_payments
WHERE (id IN ($[pid]))
-------- or  ((payment_request_body #>> '{email}')  = ' $[pemail]')
ORDER BY id DESC;

-- Partner seller
-- @WbResult partner_seller
SELECT *
FROM r_partner_sellers 
WHERE id IN (SELECT partner_seller_id FROM r_payment_events WHERE payment_id IN ($[pid]));

-- Partner seller snaps
-- @WbResult partner_seller_events_snap
SELECT *
FROM r_partner_seller_snap_events 
WHERE seller_id IN (SELECT partner_seller_id FROM r_payment_events WHERE payment_id IN ($[pid]));



-- @WbResult pr
SELECT *
FROM r_cc_authorizations
WHERE payment_id IN ($[pid]);

--@WbResult decisions
SELECT *
FROM decisions
WHERE (r_payment_id IN ($[pid]))

ORDER BY id DESC;

-- Partner end user id
-- @WbResult peu_snap_full
SELECT *
FROM r_peu_snap_events 
WHERE peu_id IN (SELECT peu_id FROM r_payment_events WHERE payment_id IN ($[pid]));


-- Partner end user id
-- @WbResult partner_user
SELECT *
FROM r_peu 
WHERE id IN (SELECT peu_id FROM r_payment_events WHERE payment_id IN ($[pid]));


-- cbs
-- @WbResult cbs
SELECT *
FROM r_chargebacks 
WHERE payment_id IN  ($[pid]);


-- Prefunds
-- @WbResult refunds
SELECT *
FROM r_refunds 
WHERE payment_id IN   ($[pid]);


-- partner_decision_events
-- @WbResult partner_decision_events
SELECT *
FROM r_partner_decision_events 
WHERE payment_id IN ($[pid]);

-- -- decision_events
-- -- @WbResult decisions
-- SELECT *
-- FROM decisions
-- WHERE r_payment_id IN ($[pid]);

