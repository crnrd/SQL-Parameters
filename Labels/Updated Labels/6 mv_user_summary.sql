drop materialized view mv_user_summary cascade;
commit;
create materialized view mv_user_summary 

(email, 
user_last_decision, 
user_last_manual_decision, 
user_risk_status,
fraud_payments, 
service_cb_or_refund_payments, 
old_approved_payments, 
approved_payments) 
as 
-- ;
with 
-- Define the payment_ids you want to go through
p_ids  as (select id, email from payments where status in (2, 13, 15,  11, 16, 22)
-- and  id < 810000 
-- order by 1 desc limit 50
), 
--Extracts the email from them and then all their payments. The PIT is defined by the max payment_id
email_p_ids as (select id, created_at, email from payments where email in (select email from p_ids) 
and status in (2, 13, 15,  11, 16, 22)
--  and id < 810000
 ),

-- aggregates all the payment label. 
all_labels as 
(select distinct on (payment_id)
pfd.payment_id,
pfd.payment_label as first_decision, 
pld.payment_label as last_decision,
pls. payment_label as last_state

from 
mv_payment_first_decision_label pfd 
left join mv_payment_last_decision_label pld on pld.payment_id = pfd.payment_id 
left join mv_payment_last_state_label pls on pls.payment_id = pfd.payment_id
where pfd.payment_id in (select id from email_p_ids)
),

--User Risk Status
user_risk_status as (select email, user_risk_status from simplex_end_users where email in (select email from email_p_ids)),


user_last_manual_decision as 
(select * from
 (select distinct on (email) 
 email, email_p_ids.id, created_at, al.last_decision 
from  email_p_ids
join (select payment_id, last_decision from all_labels
where last_decision in ('approved', 'declined_fraud', 'declined_potential_fraud')) 
 al on al.payment_id = email_p_ids.id
order by email, created_at desc )
 manual_decisions
where last_decision is not null)
,

user_last_decision as 
(select * from (select distinct on (email) email, created_at, al.last_decision 
from  email_p_ids
left join (select payment_id, last_decision from all_labels) 
 al on al.payment_id = email_p_ids.id
order by email, created_at desc ) decisions
)

select distinct user_payment_stats.email, 
uld.last_decision as user_last_decision, 
ulmd.last_decision as user_last_menual_decision, 
user_risk_status, 
sum(fraud_payment) as fraud_payments, 
sum(service_cb_or_refund_payment) as service_cb_or_refund_payments, 
sum(old_approved_payment) as old_approved_payments, 
sum(approved_payment) as approved_payments 



from 
(select
 p.email, p.id,
 urs.user_risk_status, 
 al.first_decision, 
 al.last_decision, 
 al.last_state,
 case when al.last_state in ('fraud') then 1 else 0 end as fraud_payment,
case when al.last_state in ('service_cb', 'refund') then 1 else 0 end as service_cb_or_refund_payment,
case when al.last_state in ('approved_old') then 1 else 0 end as old_approved_payment,
case when al.last_state in ('approved') then 1 else 0 end as approved_payment


from email_p_ids p
left join user_risk_status urs on urs.email = p.email
left join all_labels al on al.payment_id = p.id
) user_payment_stats
left join user_last_decision uld on uld.email = user_payment_stats.email
left join user_last_manual_decision ulmd on ulmd.email = user_payment_stats.email

group by 1, 2,3, 4


 ;

commit;
