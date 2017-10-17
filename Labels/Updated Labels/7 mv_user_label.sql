 drop materialized view mv_user_label cascade;
commit;
create materialized view mv_user_label (email, user_label)
as 

--commit;
with 
p_ids  as (select id, email from payments where status in (2, 13, 15,  11, 16, 22)
-- and  id < 810000 
)

select email,
case 
when fraud_payments > 0 then 'fraudalent_user'
when third_party_fraud_payment > 0 then 'third_party_fraud_user'
when friendly_fraud_payment > 0 then 'friendly_fraudster'
when service_cb_or_refund_payments > 0 then 'service_cb_or_refunded_user'
when user_risk_status = 'decline' then 'urs_decline' 
when user_risk_status = 'manual' then 'urs_manual' 
when user_last_manual_decision = 'declined_fraud' then 'bad_user' -- should divide here into types
when user_last_manual_decision = 'declined_potential_fraud' and old_approved_payments > 0 then 'declined_but_approved_before_without_cb'
when user_last_manual_decision = 'declined_potential_fraud' then 'bad_user'
when old_approved_payments > 0 then 'good_user'
when user_last_decision in ('cancelled_manual_ver', 'cancelled_auto_ver') and approved_payments > 0 then 'approved_user_cancelled_last_payment'
when user_last_decision in ('cancelled_manual_ver', 'cancelled_auto_ver')  then 'not_approved_user_cancelled_last_payment'
when approved_payments > 0 then 'approved_by_analyst' 
when user_last_decision in ('auto_approved', 'cutoff_approved') then 'auto_approved'
when user_last_decision in ('auto_declined') then 'auto_declined'
when user_last_decision in ('cutoff_declined') then 'cutoff_auto_declined'
when user_last_manual_decision = 'declined_policy' then 'declined_policy'
else 'other' end as user_label


from 
mv_user_summary us 
where us.email in (select email from p_ids) 

;
commit;
select distinct user_label, count(*) from mv_new_user_label group by 1;
select * from user_summary order by 1 desc limit 5000;

select distinct user_label from mv_user_label_or limit 5000 ;
select * from mv_all_labels limit 1000 ; ;




