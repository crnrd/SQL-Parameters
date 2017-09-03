
with p_ids as (select p.id , pa.service_type as partner_type from payments p
join partner_end_users peu on peu.id = p.partner_end_user_id
join partners pa on pa.id = peu.partner_id  where p.status = 16 and p.id between 200000 and 600000), 

all_labels as (select * from mv_all_labels where payment_id in (select id from p_ids)),
p_dec as (select * from mv_payment_decisions where payment_id in (select id from p_ids)),


ver_req as (select distinct on (payment_id) payment_id, inserted_at, 
case when requesting_user_id <= 0 then 'Auto' 
else 'Manual' end as ver_requesting_user 
from verification_requests where payment_id in (select id from p_ids)
and allow_verifications #>> '{0}' in ('photo_selfie', 'video_selfie') order by payment_id, inserted_at), 

canc_due_to_quote as (select distinct payment_id from comments where text_data = 'Cancelled because of change in BTC rate (broker policy)' and payment_id in (select id from p_ids)),

canc_due_to_off_hours as (select distinct payment_id from decisions where payment_id in (select id from p_ids) and 
application_name = 'EndUser' and reason = 'Refused Verification Off Hours'),

ver_type as (
select 
p_ids.id as payment_id, 
case when p_dec.post_auth_decision = 'verify' and post_auth_reason = 'Policy require photo selfie with *THIS PAYMENT* credit card with *SAME PERSON* name on card' then 'Bitstamp Selfie'
when p_dec.post_auth_decision = 'verify' and post_auth_reason in  ('should have kyc identity', 'fail sanction screening, should have kyc identity') then 'KYC verification' 
when p_dec.post_auth_decision = 'verify' and post_auth_reason in ('amount above cap limit unverified cc',
'amount above cap limit verified only by 3ds',
'not verified card above limit',
'returning strong user over limit 1',
'returning weak user over limit 1') then 'Simplex Risk Policy Selfie'
when  p_dec.post_auth_decision = 'verify' and post_auth_reason in ('returning user with failed verification in previous payment 1') then 'Returning verification'
when p_dec.post_auth_decision = 'verify' then 'Verify Risky User'
when ver_req.ver_requesting_user = 'Manual' then 'Manual_Verification'
when (p_ids.id in (select payment_id from  canc_due_to_quote)) or 
(p_dec.batch_decision = 'cancelled' and p_dec.batch_reason in  ('Cancelled because of change in BTC rate (internal policy)', 
'Cancelled because of change in BTC rate (broker policy)')) then 'Cancelled Due to Quote'
when p_ids.id in (select payment_id from canc_due_to_off_hours) then 'Cancelled Off Hours'
else 'Other'
end as verification_type
from 
p_ids left join 
mv_payment_decisions p_dec on p_dec.payment_id = p_ids.id
left join 
 ver_req on ver_req.payment_id = p_ids.id

)

select * from (
select distinct on (p_ids.id) p_ids.id as payment_id, verification_type
from 
p_ids 
left join all_labels al on p_ids.id = al.payment_id
left join ver_req vr on vr.payment_id = p_ids.id
left join ver_type vt on vt.payment_id = p_ids.id
) a
where 
verification_type = 'Other' 
-- and
--  payment_id = 561237
-- order by 1 desc
 limit 50;
