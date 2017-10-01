WbVarDef email_domain='$[?domain]';
WbVarDef hrs_back='$[?hrs]';
WbVarDef days_back='$[?days]';
WbVarDef p_ids = @"select string_agg(id::text, ',') from payments p where  substring(email from '@(.*)$') = '$[email_domain]'
and p.created_at > (now() - interval '$[hrs_back] hours')";
WbVarDef p_ids_weeks_back = @"select string_agg(id::text, ',') from payments p where  substring(email from '@(.*)$') = '$[email_domain]'
and p.created_at between  (now() - interval '$[days_back] days' -  interval '$[hrs_back] hours') 
and 
 (now() - interval '$[hrs_back] hours')";




--@WbResult Payment Details


select id, p.created_at, email,
status, 
 credit_card,
  partner_end_user_id, simplex_end_user_id, 
  first_name_card, 
  last_name_card, 
  first_name, 
  last_name, 
  total_amount, 
  country, 
  state, 
  city, 
  address1,
  address2, 
  zipcode, 
  dec.*
  


  from payments p
left join (select distinct on  (payment_id) payment_id,  application_name,  decision, reason, created_at
 from decisions d where application_name in ('Bender_Auto_Decide', 'Manual', 'Nibbler_post_kyc', 'Bender_Pre_Auth_Decide') and payment_id in ($[p_ids]) group by 1,2,3,4, 5 order by 1, d.created_at desc ) dec
on dec.payment_id = p.id
where id in  ($[p_ids])
 
;



--@WbResult Past Payment Details


select id, p.created_at, email,
status, 
 credit_card,
  partner_end_user_id, simplex_end_user_id, 
  first_name_card, 
  last_name_card, 
  first_name, 
  last_name, 
  total_amount, 
  country, 
  state, 
  city, 
  address1,
  address2, 
  zipcode, 
  dec.*
  


  from payments p
left join (select distinct on  (payment_id) payment_id,  application_name,  decision, reason, created_at 
from decisions d where application_name in ('Bender_Auto_Decide', 'Manual', 'Nibbler_post_kyc', 'Bender_Pre_Auth_Decide') and payment_id in ($[p_ids]) group by 1,2,3,4, 5 order by 1, d.created_at desc ) dec
on dec.payment_id = p.id
where id in  ($[p_ids_weeks_back])
order by 1 desc limit 50
 ;
--@WbResult Aggregations

select *, 
case when avg_per_day_days_back != 0 then num_last_hrs/avg_per_day_days_back 
else 0 end as ratio
from (
select 
'num payments'  as  measurement,
coalesce (sum(case when id in ($[p_ids]) then 1 else 0 end), 0) as num_last_hrs,
coalesce (sum(case when id in ($[p_ids_weeks_back]) then 1 else 0 end), 0)/$[days_back]::float as  avg_per_day_days_back 
from payments where id in ($[p_ids]) or id in ($[p_ids_weeks_back])

union all

select 
'num users' as  measurement,
count(distinct email) as num_last_hrs, 
(select count(distinct email)/$[days_back]::float as num
from payments where id in ($[p_ids_weeks_back])) as avg_per_day_days_back
from payments where id in ($[p_ids]) 

union all
select 
'num not analytic approves' as measurement, 
coalesce (sum(case when payment_id in ($[p_ids]) then 1 else 0 end),0) as num_last_hrs, 
coalesce (sum(case when payment_id in ($[p_ids_weeks_back]) then 1 else 0 end),0)/$[days_back]::float as avg_per_day_days_back
from 
(select distinct on 
 (payment_id) payment_id, 
  application_name,  decision, reason, created_at from decisions d where 
  application_name in ('Bender_Auto_Decide', 'Nibbler_post_kyc')
  and reason in ('approve_threeds_liable', 'decent user nothing bad under limit')
   and (payment_id in ($[p_ids]) or payment_id in ($[p_ids_weeks_back])) 
   group by 1,2,3,4, 5 order by 1, d.created_at desc   
 ) dec


union all
select 
'num declines' as measurement, 
coalesce (sum(case when payment_id in ($[p_ids]) then 1 else 0 end), 0) as num_last_hrs, 
coalesce (sum(case when payment_id in ($[p_ids_weeks_back]) then 1 else 0 end), 0)/$[days_back]::float as avg_per_day_days_back
from 
(select distinct on 
 (payment_id) payment_id, 
  application_name,  decision, reason, created_at from decisions d where 
  application_name in ('Bender_Auto_Decide', 'Nibbler_post_kyc', 'Manual')
  and decision  = 'declined' 
   and (payment_id in ($[p_ids]) or payment_id in ($[p_ids_weeks_back])) 
   group by 1,2,3,4, 5 order by 1, d.created_at desc   
 ) dec

union all

select 
'total approved amount'  as  measurement,
coalesce (sum(case when id in ($[p_ids]) then total_amount else 0 end), 0)  as num_last_hrs,
coalesce (sum(case when id in ($[p_ids_weeks_back]) then total_amount else 0 end), 0)/$[days_back]::float  as avg_per_day_days_back 
from payments where (id in ($[p_ids]) or id in ($[p_ids_weeks_back])) and status = 2

union all 


select 
 
'num cbs'  as  measurement,
coalesce (sum(case when payment_id in ($[p_ids]) then 1 else 0 end), 0)  as num_last_hrs,
coalesce (sum(case when payment_id in ($[p_ids_weeks_back]) then 1 else 0 end), 0)/$[days_back]::float  as avg_per_day_days_back 
from chargebacks where payment_id in ($[p_ids]) or payment_id in ($[p_ids_weeks_back])


union all 


 
select 
'num fws'  as  measurement,
coalesce (sum(case when payment_id in ($[p_ids]) then 1 else 0 end), 0)  as num_last_hrs,
coalesce (sum(case when payment_id in ($[p_ids_weeks_back]) then 1 else 0 end), 0)/$[days_back]::float  as avg_per_day_days_back 
from fraud_warnings where payment_id in ($[p_ids]) or payment_id in ($[p_ids_weeks_back])
) agg

;

