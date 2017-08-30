
with p_ids as (select id, status from payments where id between 530000 and 700000 and status in (2, 11, 16, 13, 15, 22)),

dec as (select * from mv_payment_decisions where payment_id in (select id from p_ids)), 



ver_req as (select distinct on (payment_id) payment_id, inserted_at, 
case when requesting_user_id <= 0 then 'Auto' 
else 'Manual' end as ver_requesting_user 
from verification_requests where payment_id in (select id from p_ids)
and allow_verifications #>> '{0}' in ('photo_selfie', 'video_selfie') order by payment_id, inserted_at)
-- (select payment_id, decision, reason, application_name, variables from decisions where  payment_id in (select id from p_ids) and application_name = 'Bender_Auto_Decide')
select * from (
select p_ids.id as payment_id,
dec.post_auth_reason as reason,  
-- dec.post_auth_decision as a_dec,
-- dec.post_auth_reason as a_reason, 
case when (al.user_label in ('not_approved_user_cancelled_last_payment')) or (al.user_label = 'other' and al.last_state ilike ('%cancelled%')) then ct.cancellation_type
when al.user_label = 'other' then al.last_state
else al.user_master_label end as label,
-- else al.user_label end as label,
(variables ->> 'ip_num_users')::int as ip_link,
 (variables ->> 'cookie_num_users')::int  as cookie_link,
  (variables ->> 'btc_address_num_users')::int  as btc_link,
 (variables ->> 'cc_num_users')::int  as cc_link,
 (variables ->> 'max_num_phone_users')::int  as phone_link, 
 (variables ->> 'partner_type')  as partner_type
-- case when (variables ->> 'ip_num_users') != 'no_data' and (variables ->> 'ip_num_users')::int > 1 then 1 else 0 end as ip_link,
-- case when (variables ->> 'cookie_num_users') != 'no_data' and (variables ->> 'cookie_num_users')::int > 1 then 1 else 0 end as cookie_link,
-- case when (variables ->> 'btc_address_num_users') != 'no_data' and (variables ->> 'btc_address_num_users')::int > 1 then 1 else 0 end as btc_link,
-- case when (variables ->> 'cc_num_users') != 'no_data' and (variables ->> 'cc_num_users')::int > 1 then 1 else 0 end as cc_link,
-- case when (variables ->> 'max_num_phone_users') != 'no_data' and (variables ->> 'max_num_phone_users')::int > 1 then 1 else 0 end as phone_link,
-- case when (variables ->> 'ip_num_users') != 'no_data' and (variables ->> 'ip_num_users')::int < 3 then 1 else 0 end as weak_ip_link,
-- case when (variables ->> 'cookie_num_users') != 'no_data' and (variables ->> 'cookie_num_users')::int < 3 then 1 else 0 end as weak_cookie_link,
-- case when (variables ->> 'btc_address_num_users') != 'no_data' and (variables ->> 'btc_address_num_users')::int < 3 then 1 else 0 end as weak_btc_link,
-- case when (variables ->> 'cc_num_users') != 'no_data' and (variables ->> 'cc_num_users')::int < 3 then 1 else 0 end as weak_cc_link,
-- case when (variables ->> 'max_num_phone_users') != 'no_data' and (variables ->> 'max_num_phone_users')::int < 3 then 1 else 0 end as weak_phone_link,
-- 
-- case when (variables ->> 'payment_model_score') != 'no_data' and (variables ->> 'payment_model_score')::float < 0.1 then 1 else 0 end as low_model_score,
-- case when (variables ->> 'mm_riskscore') != 'no_data' and (variables ->> 'mm_riskscore')::float < 5 then 1 else 0 end as low_mm_riskscore,
-- 
-- case when variables ->> 'linked_suspiciously' = 'true' then 1 else 0 end as linked_suspiciously,
-- case when variables ->> 'id_match' = 'true' then 1 else 0 end as id_match, 
-- case when variables ->> 'verified_phone_match' = 'true' then 1 else 0 end as verified_phone_match, 
-- case when variables ->> 'good_user_three_ds_avs_match' = 'true' then 1 else 0 end as good_user_three_ds_avs_match, 
-- case when variables ->> 'phone_bin_ip_location_match' = 'true' then 1 else 0 end as phone_bin_ip_location_match

-- distinct reason, count(distinct payment_id) as num_payments
 from p_ids 
 join  dec on dec.payment_id = p_ids.id
left join  mv_all_labels al on al.payment_id = p_ids.id
left join mv_cancellation_type ct on p_ids.id = ct.payment_id
left join ver_req on ver_req.payment_id = p_ids.id
left join (select payment_id, variables #> '{Analytic, variables, Analytic}' as variables from decisions where application_name = 'Bender_Auto_Decide') var on var.payment_id = p_ids.id

where 
--  ver_req.ver_requesting_user = 'Manual'
dec.post_auth_decision = 'verify' 
and dec.post_auth_reason = 'verify_linked_strongly_to_another_user_not_verified_card_by_selfie'
and variables ->> 'user_previously_reviewed_by_analyst' = 'false')a
-- where  label = 'bad_user'
-- group by 1
;

