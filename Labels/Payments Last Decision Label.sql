

-- create materialized view ma_view_payment_last_decision_label (payment_id, payment_label)
-- as 
with 
p_ids as (select id, status from payments where status in (2, 13, 15,  11, 16, 22) and 
id < 814818
), 
ver_req as (select distinct on (payment_id) payment_id, inserted_at, 
case when requesting_user_id <= 0 then 'Auto' 
else 'Manual' end as ver_requesting_user from verification_requests where payment_id in (select id from p_ids)
and allow_verifications #>> '{0}' in ('photo_selfie', 'video_selfie') order by payment_id, inserted_at)

select * from (
select pd.payment_id, 
case
--Offline Decisions 
when offline_manual_decision = 'declined' and (offline_manual_strength = 'Strong' 
or offline_manual_reason in ('REAL REAL REAL FRAUD!')) -- Add here the new reasons from the DSS when ready
  then 'declined_fraud'
when offline_manual_decision = 'declined' and 
(offline_manual_strength = 'Weak' or offline_manual_reason in ('MAYBE ITS FRAUD!'))then 'declined_potential_fraud' -- Add here the new reasons from the DSS when ready
when  offline_manual_decision = 'approved' then 'approved'
--Manual Decisions
when manual_decision = 'declined' and (manual_strength = 'Strong' 
or manual_reason in ('REAL REAL REAL FRAUD!')) -- Add here the new reasons from the DSS when ready
  then 'declined_fraud'  
when manual_decision = 'declined' and 
(manual_strength = 'Weak' or manual_reason in ('MAYBE ITS FRAUD!')) then 'declined_potential_fraud' -- Add here the new reasons from the DSS when ready
when  manual_decision = 'approved' then 'approved'
when ver_requesting_user = 'Manual'
--  and p_ids.status = 16 
   then 'cancelled_manual_ver' 
when post_auth_decision = 'verify' and post_auth_reason in ('Policy require photo selfie with *THIS PAYMENT* credit card with *SAME PERSON* name on card',
                                                                  'should have kyc identity') then 'cancelled_auto_policy_ver'
when post_auth_decision = 'verify' and p_ids.status = 16 then 'cancelled_auto_ver'
when p_ids.status = 16 then 'cancelled_other_reason'
when post_auth_decision = 'approved' then 'auto_approved' 
when post_auth_decision = 'declined' and post_auth_reason in ('fatf country', 'underaged') then 'policy_auto_declined' 
when post_auth_decision = 'declined' then 'auto_declined' 
when cutoff_decision = 'approved'  or batch_decision = 'approved' then 'cutoff_approved'
when cutoff_decision = 'declined' or batch_decision = 'declined'  then 'cutoff_declined' 

else 'other' end as payment_label

-- Cancelled manually or by EndUser are currently under 'other', should decide if need to get to this resolution

from ma_view_payment_decisions pd
left join ver_req on pd.payment_id = ver_req.payment_id
left join p_ids on pd.payment_id = p_ids.id
where pd.payment_id in (select id from p_ids))labels 
;
commit;
select count(*) from ma_view_payment_last_decision_label;
select distinct payment_label, count(*) from ma_view_payment_last_decision_label group by 1 order by 1 desc limit 50;
-- select * from ma_view_payment_last_decision_label order by 1 desc limit 50;




;


