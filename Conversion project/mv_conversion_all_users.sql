CREATE MATERIALIZED VIEW mv_conversion_all_users AS


select
  distinct on (partner_end_user_id)
    partner_end_user_id,
    mcap.*
FROM
  mv_conversion_all_payments mcap,
  payments p
WHERE
  p.id = mcap.s_payment_id
order by partner_end_user_id desc, farthest_stage_for_payment desc, s_payment_id desc;