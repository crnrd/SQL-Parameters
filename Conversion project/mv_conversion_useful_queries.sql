-- conversion summary by payments

select
  farthest_stage_for_payment,
  status_in_farthest_stage,
  reason_for_farthest_stage,
  count(s_payment_id)
 FROM
   mv_conversion_all_payments
  group by 1,2,3
  order by 1,2,3;
