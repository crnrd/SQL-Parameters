CREATE MATERIALIZED VIEW mv_conversion_pre_auth AS


WITH conversion_pre_auth_last_decision_for_payment AS
(SELECT
   payment_id,
   max(id) AS last_decision
 FROM
   decisions
 WHERE
   application_name = 'Bender_Pre_Auth_Decide'
 GROUP BY 1)

SELECT
  d.payment_id AS s_payment_id,
  CASE
  WHEN decision IN ('auth', 'exempt_from_three_ds') THEN 'success'
  WHEN decision IN ('reject_by_policy', 'card_name_mismatch') THEN 'failed'
  ELSE 'unexpected value' END AS payment_status_in_stage,

  CASE
  WHEN decision IN ('auth') THEN 'sent to 3DS'
  WHEN decision IN ('exempt_from_three_ds') THEN 'sent to Non-3DS'
  WHEN decision IN ('reject_by_policy') THEN 'rejected by policy'
  WHEN decision IN ('card_name_mismatch') THEN 'rejected for name mismatch'
  ELSE 'unexpected value' END AS status_reason_in_stage
FROM
  decisions d,
  conversion_pre_auth_last_decision_for_payment ldfp
WHERE
  d.id = ldfp.last_decision
ORDER BY 1 DESC;

