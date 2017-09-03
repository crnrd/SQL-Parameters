with
 p_ids as (select p.id, pa.service_type as partner_type from payments p
join partner_end_users peu on peu.id = p.partner_end_user_id
join partners pa on pa.id = peu.partner_id 
 where (p.id between 410000 and 810000) and status in (2, 11, 13, 15, 16, 22)),
 ver_req as (select distinct on (payment_id) payment_id, inserted_at, 
case when requesting_user_id <= 0 then 'Auto' 
else 'Manual' end as ver_requesting_user from verification_requests where payment_id in (select id from p_ids)
and allow_verifications #>> '{0}' in ('photo_selfie', 'video_selfie') order by payment_id, inserted_at),
p_dec as (select * from ma_view_payment_decisions where payment_id in (select id from p_ids)), 
all_labels as (select * from mv_new_all_labels where payment_id in (select id from p_ids))



select *, 
sum(num_payments) over (partition by auto_verification_type) as p_per_ver_tyoe, 
100*num_payments/sum(num_payments) over (partition by auto_verification_type) as perc_per_ver_type
from (

select distinct auto_verification_type,
partner_type,
 last_state as label , 
  count(payment_id) as num_payments
from (

select 
al.payment_id, 
partner_type, 
case when p_dec.post_auth_decision = 'verify' and post_auth_reason = 'Policy require photo selfie with *THIS PAYMENT* credit card with *SAME PERSON* name on card' then 'Bitstamp Selfie'
when p_dec.post_auth_decision = 'verify' and post_auth_reason in  ('should have kyc identity', 'fail sanction screening, should have kyc identity') then 'KYC verification' 
when p_dec.post_auth_decision = 'verify' and post_auth_reason in ('amount above cap limit unverified cc',
'amount above cap limit verified only by 3ds',
'not verified card above limit',
'returning strong user over limit 1',
'returning weak user over limit 1') then 'Simplex Risk Policy Selfie'
when  p_dec.post_auth_decision = 'verify' and post_auth_reason in( 'returning user with failed verification in previous payment 1') then 'Returning verifcation'
when p_dec.post_auth_decision = 'verify' then 'Verify Risky User'
end as auto_verification_type, 
last_state, 
user_label
 


from  all_labels al 
left join ver_req on ver_req.payment_id = al.payment_id
left join p_dec on p_dec.payment_id = al.payment_id
left join p_ids on p_ids.id = al.payment_id
) a group by 1,2,3) b where auto_verification_type is not null;


select * from mv_user_label where payment_id = 503565;



