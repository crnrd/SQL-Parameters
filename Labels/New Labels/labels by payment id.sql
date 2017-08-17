WbVarDef pid='$[?id]';




--@WbResult payment_decisions
SELECT *
FROM mv_payment_decisions
WHERE (payment_id IN ($[pid]))
ORDER BY 1 DESC;


--@WbResult fraud_inputs
SELECT *
FROM mv_fraud_inputs
WHERE (payment_id IN ($[pid]))
ORDER BY 1 DESC;

--@WbResult user_summary
with
 p as (select id, email from payments where id in ($[pid]))
SELECT *
FROM mv_user_summary
WHERE (email IN (select email from p))
ORDER BY 1 DESC;


--@WbResult first_decision
SELECT *
FROM mv_payment_first_decision_label
WHERE (payment_id IN ($[pid]))
ORDER BY 1 DESC;

--@WbResult last_decision
SELECT *
FROM mv_payment_last_decision_label 
WHERE (payment_id IN ($[pid]))
ORDER BY 1 DESC;


--@WbResult last_state
SELECT *
FROM mv_payment_last_state_label
WHERE (payment_id IN ($[pid]))
ORDER BY 1 DESC;

--@WbResult user_label

with p as (select id, email from payments where id in ($[pid]))
SELECT *
FROM mv_user_label
WHERE (email IN (select email from p))
ORDER BY 1 DESC;

--@WbResult all_labels

SELECT *
FROM mv_all_labels
WHERE (payment_id IN ($[pid]))
ORDER BY 1 DESC;;




