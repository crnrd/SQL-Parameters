CREATE MATERIALIZED VIEW mv_conversion_post_auth AS

SELECT
  d.payment_id AS s_payment_id,
  CASE
  WHEN decision IN ('approved', 'verify') THEN 'success'
  WHEN decision IN ('declined', 'manual') THEN 'failed'
  ELSE 'unexpected value' END AS payment_status_in_stage,

  CASE
  WHEN decision IN ('verify') and reason in ('should have kyc identity') and variables#>>'{Analytic, audit, ruling_decision, decision}' = 'verify' THEN 'verify: sent to selfie + kyc'
  WHEN decision IN ('verify') and reason in ('should have kyc identity') and variables#>>'{Analytic, audit, ruling_decision, decision}' = 'approved'  THEN 'verify: sent to kyc'
  WHEN decision IN ('verify') THEN 'verify: sent to selfie'
  ELSE decision::text END AS status_reason_in_stage
FROM
  decisions d
WHERE
  application_name = 'Bender_Auto_Decide'
ORDER BY 1 DESC;