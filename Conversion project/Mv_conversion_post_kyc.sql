CREATE MATERIALIZED VIEW mv_conversion_post_kyc AS

with p_ids as (
  select
    pi.id
  from
    payments p,
    mv_conversion_payment_ids pi
  WHERE
    p.id = pi.id
    and p.status != 16)

SELECT
  d.payment_id AS s_payment_id,
  CASE
  WHEN decision IN ('approved') THEN 'success'
  WHEN decision IN ('declined') THEN 'failed'
  WHEN decision IN ('manual') THEN NULL
  ELSE 'unexpected value' END AS payment_status_in_stage,

  decision::text status_reason_in_stage
FROM
  decisions d,
  p_ids
WHERE
  p_ids.id = d.payment_id
  and application_name = 'Nibbler_post_kyc'
ORDER BY 1 DESC;

