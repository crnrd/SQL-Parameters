refresh materialized view ma_view_payment_decisions;
 
drop materialized view ma_view_payment_decisions;

create  materialized view ma_view_payment_decisions
 (payment_id, 
pre_auth_decision, 
pre_auth_reason,  
post_auth_decision, 
post_auth_reason, 
manual_decision, 
manual_reason,
manual_strength, 
offline_manual_decision, 
offline_manual_reason,
offline_manual_strength, 
post_kyc_decision, 
post_kyc_reason, 
cutoff_decision, 
cutoff_reason,
batch_decision, 
batch_reason)

as


with 
p_ids as (select id from payments where status in (2, 13, 15,  11, 16, 22) and 
id < 820000
order by 1 
),

pre_auth_decision as (select distinct on (payment_id) payment_id, decision, reason from decisions where application_name = 'Bender_Pre_Auth_Decide'
  order by payment_id, created_at desc) , 

post_auth_decision as (select payment_id, decision, reason from decisions where payment_id in (select id from p_ids) and application_name = 'Bender_Auto_Decide'), 

cutoff_decision as (select payment_id, decision, reason from decisions where payment_id in (select id from p_ids) and application_name = 'Bender_Pending_Payment_Manual'),

batch_decision as (select payment_id, decision, reason from decisions where payment_id in (select id from p_ids) and application_name = 'Bender_Manual'),

post_kyc_decision as (select payment_id, decision, reason from decisions where payment_id in (select id from p_ids) and application_name = 'Nibbler_post_kyc'),

manual_decision  as (select payment_id, decision, reason, variables#>>'{strength}' as strength from decisions where payment_id in (select id from p_ids) and application_name = 'Manual'
and decision in ('approved', 'declined')),

manual_offline_decision  as (select payment_id, decision, variables#>>'{strength}' as strength, reason from decisions where payment_id in (select id from p_ids) and application_name = 'Offline Manual'
and decision in ('approved', 'declined')),

ver_req as (select distinct on (payment_id) payment_id, inserted_at, 
case when requesting_user_id <= 0 then 'Auto' 
else 'Manual' end as ver_requesting_user from verification_requests where payment_id in (select id from p_ids)
and allow_verifications #>> '{0}' in ('photo_selfie', 'video_selfie') order by payment_id, inserted_at)


select p_ids.id, 
prad.decision as pre_auth_decision, 
prad.reason as pre_auth_reason, 
pad.decision as post_auth_decision, 
pad.reason as post_auth_reason, 
md.decision as manual_decision, 
md.reason as manual_reason,
md.strength as  manual_strength, 
omd.decision as offline_manual_decision, 
omd.reason as offline_manual_reason,
omd.strength as  offline_manual_strength, 
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
left join manual_offline_decision omd on omd.payment_id = p_ids.id
left join cutoff_decision cd on cd.payment_id = p_ids.id
left join batch_decision bd on bd.payment_id = p_ids.id
;
commit;

select count(*) from ma_view_payment_decisions_2;
