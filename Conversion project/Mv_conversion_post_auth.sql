CREATE MATERIALIZED VIEW mv_conversion_post_auth AS

SELECT
  d.payment_id AS s_payment_id,
  CASE
  WHEN decision IN ('approved', 'verify') THEN 'success'
  WHEN decision IN ('declined', 'manual') THEN 'failed'
  ELSE 'unexpected value' END AS payment_status_in_stage,

  CASE
  WHEN decision IN ('verify') and reason in ('should have kyc identity') and variables#>>'{Analytic, audit, ruling_decision, decision}' = 'verify' THEN 'verify_selfie_and_kyc'
  WHEN decision IN ('verify') and reason in ('should have kyc identity') and variables#>>'{Analytic, audit, ruling_decision, decision}' = 'approved'  THEN 'verify_kyc'
  WHEN decision IN ('verify') THEN 'verify_selfie'
  ELSE decision::text END AS status_reason_in_stage
FROM
  decisions d,
  mv_conversion_payment_ids p_ids
WHERE
  d.payment_id = p_ids.id
  and application_name = 'Bender_Auto_Decide'
ORDER BY 1 DESC;