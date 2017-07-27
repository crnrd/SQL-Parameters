with sim_results as (select payment_id, decision, reason 
from simulator_results sr 
left join simulator_parameters sp on sp.id = sr.parameter_id where run_id = 3149),
labels as (select *, 
case 
when  user_label in ('good_user', 'approved_by_analyst', 'auto_approved') then 'good'
when user_label in ('fraudalent_user', 'urs_decline', 'bad_user') then 'bad'
when user_label in ('auto_declined') then 'auto_declined'
when user_label in ('not_approved_user_cancelled_last_payment', 'approved_user_cancelled_last_payment') then 'cancelled'
else user_label
end  as final_user_label from mv_new_all_labels where payment_id in (select payment_id from sim_results))


select distinct reason, count(payment_id) from sim_results 
where decision = 'manual' group by 1

-- select decision, num_payments, sum(num_payments) over () as total_payments, 
-- 100*num_payments/sum(num_payments) over () as perc_payments from (
-- select distinct decision, count(distinct payment_id) num_payments
-- from sim_results  group by 1 ) a order by 2 desc
;

select 
label, 
num_payments, 
sum(num_payments) over () as total_payments,
100*num_payments/sum(num_payments) over () as perc_payments
from (

select 
distinct 
-- user_label
-- last_state
final_user_label
as label,
count(distinct sr.payment_id) num_payments
from sim_results sr
left join labels l on l.payment_id = sr.payment_id
where sr.decision = 'approved'
group by 1 order by 2) a; 



