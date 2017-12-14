

select
  distinct on (payment_id)
  payment_id as s_payment_id,
  CASE
  WHEN (select max(id) from user_browser_events ube2 where ube2.payment_id = ube.payment_id and ube2.event_type = 'validate') is not null then 'success'
  else 'failed' end as payment_status_in_stage

FROM
  user_browser_events ube
order by payment_id desc
limit 50;

select
*

FROM
  user_browser_events
WHERE
  payment_id = 1866547
order by 1 asc;


1880343
1880342
1880341
1880340
1880339
1880338
1880337
1880336
1880335
1880334

1880328
1880328
1880328
1880328
1880328
1880328
1880328
1880328
