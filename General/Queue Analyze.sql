with p_ids as (select id, partner_end_user_id from payments where status = 1),

ver_req as (select distinct on (payment_id) payment_id, inserted_at, 
case when finalized_at is not null then 'Uploaded' else 'Pending' end as verification_status, 
case when requesting_user_id <= 0 then 'Auto' 
else 'Manual' end as ver_requesting_user from verification_requests where payment_id in (select id from p_ids)
and allow_verifications #>> '{0}' in ('photo_selfie', 'video_selfie') order by payment_id, inserted_at),

post_auth_decision as (select distinct on (payment_id) payment_id, created_at, decision, reason,
(variables#>> '{Analytic, variables, Analytic, risky_user}') as risky_user
 from decisions 
where application_name = 'Bender_Auto_Decide' and payment_id in (select id from p_ids) order by payment_id,  created_at),
cutoff_decision as (select distinct on (payment_id) payment_id, created_at,  decision, reason from decisions 
where application_name = 'Bender_Pending_Payment_Manual' and payment_id in (select id from p_ids) order by payment_id,  created_at)



select payment_id from (

select p_ids.id as payment_id, pa.name, 
pad.decision as post_auth_decision, 
pad.reason as post_auth_reason, 
pad.risky_user, 
cd.decision as cutoff_decision, 
cd.reason as cutoff_reason, 
vr.verification_status, 
vr.ver_requesting_user

from p_ids left join ver_req on p_ids.id = ver_req.payment_id
left join post_auth_decision pad on p_ids.id = pad.payment_id
left join cutoff_decision cd on p_ids.id = cd.payment_id
left join ver_req vr on vr.payment_id = p_ids.id
left join partner_end_users peu on peu.id = p_ids.partner_end_user_id
left join partners pa on pa.id = peu.partner_id 

order by 1 desc) a
where
verification_status is null
and post_auth_decision = 'manual' and cutoff_decision is null
and post_auth_reason not in ('age above limit with no manual approvals', 'should have kyc identity')
-- verification_status != 'Pending' 
--  and not (risky_user = 'true' and verification_status = 'Uploaded')
;
