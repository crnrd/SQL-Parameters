--




with 
p_ids as (select id from payments where status in (2, 13, 15,  11, 16, 22) and 
id < 820000
order by 1 desc 
),

pre_auth_decision as (select payment_id, decision, reason from decisions where payment_id in (select id from p_ids) and application_name = 'Bender_Pre_Auth_Decide'), 

post_auth_decision as (select payment_id, decision, reason from decisions where payment_id in (select id from p_ids) and application_name = 'Bender_Auto_Decide'), 

cutoff_decision as (select payment_id, decision, reason from decisions where payment_id in (select id from p_ids) and application_name = 'Bender_Pending_Payment_Manual'),

batch_decision as (select payment_id, decision, reason from decisions where payment_id in (select id from p_ids) and application_name = 'Bender_Manual'),

post_kyc_decision as (select payment_id, decision, reason from decisions where payment_id in (select id from p_ids) and application_name = 'Nibbler_post_kyc'),

manual_decision  as (select payment_id, decision, reason,  variables#>>'{strength}' as strength from decisions where payment_id in (select id from p_ids) and application_name = 'Manual'),

ver_req as (select distinct on (payment_id) payment_id, inserted_at, 
case when requesting_user_id <= 0 then 'Auto' 
else 'Manual' end as ver_requesting_user from verification_requests where payment_id in (select id from p_ids)
and allow_verifications #>> '{0}' in ('photo_selfie', 'video_selfie') order by payment_id, inserted_at),

payment_decisions as (
select p_ids.id, 
prad.decision as pre_auth_decision, 
prad.reason as pre_auth_reason, 
pad.decision as post_auth_decision, 
pad.reason as post_auth_reason, 
md.decision as manual_decision, 
md.reason as manual_reason,
md.strength as manual_strength,
pkyc.decision as post_kyc_decision, 
pkyc.reason as post_kyc_reason, 
cd.decision as cutoff_decision, 
cd.reason as cutoff_reason,
bd.decision as batch_decision, 
bd.reason as batch_reason

from p_ids 
left join pre_auth_decision prad on prad.payment_id = p_ids.id
left join post_auth_decision pad on pad.payment_id = p_ids.id
left join post_kyc_decision pkyc on pkyc.payment_id = p_ids.id
left join manual_decision md on md.payment_id = p_ids.id
left join cutoff_decision cd on cd.payment_id = p_ids.id
left join batch_decision bd on bd.payment_id = p_ids.id
)

select * from (

select pd.id, 
case when post_auth_decision = 'declined' or post_kyc_decision = 'declined' then 'auto_declined'
when post_auth_decision = 'approved' or post_kyc_decision = 'approved' then 'auto_approved'
when post_auth_decision = 'verify' and post_auth_reason in ('Policy require photo selfie with *THIS PAYMENT* credit card with *SAME PERSON* name on card',
                                                                  'should have kyc identity') then 'auto_policy_verify'
when post_auth_decision = 'verify' then 'auto_risk_verify'
when ver_requesting_user = 'Manual' then 'verify' 
when manual_decision = 'declined' and (manual_strength = 'Strong' 
or manual_reason in ('REAL REAL REAL FRAUD!')) -- Add here the new reasons from the DSS when ready
  then 'declined_fraud'
  
when manual_decision = 'declined' and (manual_strength = 'Weak' or manual_reason in ('MAYBE ITS FRAUD!'))then 'declined_potential_fraud' -- Add here the new reasons from the DSS when ready
when manual_decision = 'approved' then 'approved'
when cutoff_decision = 'approved'  or batch_decision = 'approved' then 'cutoff_approved'
when cutoff_decision = 'declined' or batch_decision = 'declined' then 'cutoff_declined' 
else 'other' end as payment_label
-- Cancelled manually or by EndUser are currently under 'other', should decide if need to get to this resolution

from payment_decisions pd
left join ver_req on pd.id = ver_req.payment_id 
) labels
-- where payment_label = 'other'




;
-- limit 500;

create  materialized view ma_view_payment_first_decision_label_2  (payment_id, payment_label) as 
with 
p_ids as (select id from payments where status in (2, 13, 15,  11, 16, 22) and 
id = 785667
order by 1
), 
ver_req as (select distinct on (payment_id) payment_id, inserted_at, 
case when requesting_user_id <= 0 then 'Auto' 
else 'Manual' end as ver_requesting_user from verification_requests where payment_id in (select id from p_ids)
and allow_verifications #>> '{0}' in ('photo_selfie', 'video_selfie') order by payment_id, inserted_at)



select * from 
(
select pd.payment_id, 
case when post_auth_decision = 'declined' or post_kyc_decision = 'declined' then 'auto_declined'
when post_auth_decision = 'approved' or post_kyc_decision = 'approved' then 'auto_approved'
when post_auth_decision = 'verify' and post_auth_reason in ('Policy require photo selfie with *THIS PAYMENT* credit card with *SAME PERSON* name on card',
                                                                  'should have kyc identity') then 'auto_policy_verify'
when post_auth_decision = 'verify' then 'auto_risk_verify'
when ver_requesting_user = 'Manual' then 'verify' 
when manual_decision = 'declined' and (manual_strength = 'Strong' 
or manual_reason in ('REAL REAL REAL FRAUD!')) -- Add here the new reasons from the DSS when ready
  then 'declined_fraud'
  
when manual_decision = 'declined' and 
(manual_strength = 'Weak' or manual_reason in ('MAYBE ITS FRAUD!'))then 'declined_potential_fraud' -- Add here the new reasons from the DSS when ready
when manual_decision = 'approved' then 'approved'
when cutoff_decision = 'approved'  or batch_decision = 'approved' then 'cutoff_approved'
when cutoff_decision = 'declined' or batch_decision = 'declined' then 'cutoff_declined' 
else 'other' end as payment_label
-- Cancelled manually or by EndUser are currently under 'other', should decide if need to get to this resolution

from ma_view_payment_decisions_2 pd
left join ver_req on pd.payment_id = ver_req.payment_id
where pd.payment_id in (select id from p_ids))labels
;
commit;

select count(*) from ma_view_payment_first_decision_label_2 ;
select count(*) from ma_view_payment_last_decision_label_2 ;
select count(*) from mv_payment_last_state_label_2 ;


