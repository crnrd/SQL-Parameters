

select
  distinct on (partner_end_user_id)
    simplex_end_user_id,
    mcap.*
FROM
  mv_conversion_all_payments mcap,
  payments p
WHERE
  p.id = mcap.s_payment_id
order by simplex_end_user_id desc, farthest_stage_for_payment desc, s_payment_id desc
limit 50;
