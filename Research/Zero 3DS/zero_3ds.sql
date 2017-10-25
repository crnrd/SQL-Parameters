
select decision, 
num_payments, 
sum(num_payments) over () as total_payments,
100*num_payments /sum(num_payments) over () as perc_payemnts
 from (
select 
distinct decision, count(distinct sp.payment_id) num_payments 
from simulator_results sr 
left join simulator_parameters sp on sr.parameter_id = sp.id
where sr.run_id = 3837
group by 1 order by 1) sim
where decision is not null 
; 


select count(distinct payment_id) from simulator_parameters where group_id = 1195;

select * from fraud_warnings order by 1 desc limit 50;
select * from chargebacks order by 1 desc limit 50;

with p_ids as 
(select id, created_at
 from payments 
where created_at between date '08-01-2017' and date '09-01-2017')

select distinct pa.name, count(p.id) total_approved, sum(case when cb_amount != 0 then 1 else 0 end) cb_amount,
 100*sum(case when cb_amount != 0 then 1 else 0 end)/count(p.id)::float as cb_perc
 from 
 (select id, partner_end_user_id,total_amount,status,
   case when 
 ((p.id in (select payment_id from chargebacks where is_simplex_liable = 'true') )
-- or 
-- (p.id in (select payment_id from fraud_warnings)
)
) then total_amount else 0 end as cb_amount
from payments p 
where p.id in (select id from p_ids)
)p
 left join partner_end_users peu on peu.id = p.partner_end_user_id 
 left join partners pa on pa.id = peu.partner_id
where 
 

p.status = 2

group by 1 order by 1 desc
;



with p_ids as 
(select id, created_at
 from payments 
where created_at between date '08-01-2017' and date '09-01-2017'), 
approved_users as (select email from payments where status = 2 and id in (select id from p_ids))



select count(distinct email) from payments 
 
where 
id in (select id from p_ids) 
and
id in (select payment_id from proc_requests 
where  (raw_response ->> 'technical_message') = 'Cardholder 3D Authentication failure!' 
 and tx_type = 'authorization' )
 and email not in (select email from approved_users)
;
select * from proc_requests order by 1 desc limit 50;
select * from proc_requests where (raw_response ->> 'technical_message') = 'Cardholder 3D Authentication failure!'  and tx_type = 'authorization' order by 1 desc limit 50;
