with c_decisions as (select payment_id, application_name, decision, variables from decisions where application_name = 'Bender_Auto_Decide'),

p_info as (
select 
al.payment_id, 
p.email, 
al.first_decision, 
pd.cutoff_decision,
pd.cutoff_reason,
last_state, 
user_label, 
case 
when  user_label in ('good_user', 'approved_by_analyst', 'auto_approved') then 'good'
when user_label in ('fraudalent_user', 'urs_decline', 'bad_user') then 'bad'
when user_label in ('auto_declined') then 'auto_declined'
when user_label in ('not_approved_user_cancelled_last_payment', 'approved_user_cancelled_last_payment') then 'cancelled'
else user_label
end  as final_user_label

from mv_new_all_labels al
inner join ma_view_payment_decisions pd on pd.payment_id = al.payment_id
inner join payments p on p.id = al.payment_id
 join c_decisions cd on cd.payment_id = al.payment_id

-- inner join decisions d on d.payment_id = al.payment_id 
where 
(al.payment_id between 420000 and 810000) 
-- and (cd.variables#>> '{Analytic, variables, Analytic, user_previously_reviewed_by_analyst}') = 'false'
and coalesce((cd.variables#>> '{Analytic, variables, Analytic, is_first}'), (cd.variables#>> '{Analytic, variables, Analytic, buyer_is_first}')) = 'true'
-- and pd.post_auth_decision = 'approved' and first_decision = 'auto_approved' 
and first_decision in ('auto_risk_verify', 'verify')
-- and pd.cutoff_decision = 'approved' and first_decision = 'cutoff_approved' 
-- and user_label not in ('other')
)


select 
-- cutoff_reason, 
-- first_decision,
-- last_state, 
-- user_label
 label, 
-- final_user_label, 
num_payments,  
-- sum(num_payments) over (partition by cutoff_reason) as total_payments,
-- 100*num_payments/sum(num_payments) over (partition by cutoff_reason) as perc_payments
sum(num_payments) over () as total_payments,
100*num_payments/sum(num_payments) over () as perc_payments
-- num_users, 
-- sum(num_users) over () as total_users,
-- 100*num_users/sum(num_users) over () as perc_users
-- sum(num_payments) over (partition by cutoff_reason) as p_per_reason,
-- 100*num_payments/sum(num_payments) over (partition by cutoff_reason) as perc_per_reason




from (
select distinct 
-- first_decision, 
-- cutoff_decision,
-- cutoff_reason,
-- last_state,
user_label as 
label,
-- final_user_label,
-- first_decision, 

count(distinct payment_id) as num_payments,
count(distinct email) as num_users



-- user_label 
from p_info 


group by 1 order by 1,2 desc

)  a order by 1, 2;




