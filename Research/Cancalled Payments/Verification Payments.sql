
with p_ids as (select id, status from payments where id between 530000 and 700000 and status in (2, 11, 16, 13, 15, 22)),

dec as (select * from mv_payment_decisions where payment_id in (select id from p_ids)), 



ver_req as (select distinct on (payment_id) payment_id, inserted_at, 
case when requesting_user_id <= 0 then 'Auto' 
else 'Manual' end as ver_requesting_user 
from verification_requests where payment_id in (select id from p_ids)
and allow_verifications #>> '{0}' in ('photo_selfie', 'video_selfie') order by payment_id, inserted_at)
-- (select payment_id, decision, reason, application_name, variables from decisions where  payment_id in (select id from p_ids) and application_name = 'Bender_Auto_Decide')

select reason,
 label,  
num_payments, 
sum(num_payments) over () as total_payments, 
-- sum(num_payments) over (partition by reason) as total_payments_per_reason, 
100*num_payments / sum(num_payments) over () as perc_payments_per_reason, 
100*num_payments /sum(num_payments) over (partition by reason) as perc_pay ,
-- ip_link, 
-- sum(ip_link) over () as total_ip_link, 
-- 100*ip_link / sum(ip_link) over () as perc_ip_link,
--   cookie_link,
--   sum(cookie_link) over () as total_cookie_link, 
-- 100*cookie_link / sum(cookie_link) over () as perc_cookie_link,
-- 
-- btc_link, 
-- sum(btc_link) over () as total_btc_link, 
-- 100*btc_link / sum(btc_link) over () as perc_btc_link,
-- 
-- cc_link, 
-- sum(cc_link) over () as total_cc_link, 
-- 100*cc_link / sum(cc_link) over () as perc_cc_link,
-- 
-- phone_link, 
-- sum(phone_link) over () as total_phone_link, 
-- 100*phone_link / sum(phone_link) over () as perc_phone_link,

linked_by_many_elements, 
sum(linked_by_many_elements) over () as total_linked_by_many_elements, 
100*linked_by_many_elements / sum(linked_by_many_elements) over () as perc_linked_by_many_elements,

not_strongly_linked,
sum(not_strongly_linked) over () as total_not_strongly_linked, 
100*not_strongly_linked / sum(not_strongly_linked) over () as perc_not_strongly_linked,
linked_suspiciously,
sum(linked_suspiciously) over () as total_linked_suspiciously, 
100*linked_suspiciously / sum(linked_suspiciously) over () as perc_linked_suspiciously,
low_mm_riskscore,
sum(low_mm_riskscore) over () as total_low_mm_riskscore,
100*low_mm_riskscore / sum(low_mm_riskscore) over () as perc_low_mm_riskscore,
simplex_approve,
sum(simplex_approve) over () as total_simplex_approve, 
100*simplex_approve / sum(simplex_approve) over () as perc_simplex_approve



from (
select distinct reason,  
label,
 count(payment_id) as num_payments, 
 sum(ip_link) as ip_link, 
 sum( cookie_link) as  cookie_link, 
  sum(btc_link) as btc_link, 
   sum(cc_link) as cc_link, 
    sum(phone_link) as phone_link, 
    sum(linked_suspiciously) as linked_suspiciously, 
    sum(case when 
    (
    weak_ip_link 
      + weak_cookie_link 
      + weak_btc_link
      + weak_cc_link
      + weak_phone_link) > 3 then 1 else 0 end) as not_strongly_linked,
      
sum(case when 
    (
    ip_link 
      + cookie_link 
      + btc_link
      + cc_link
      + phone_link) > 2 then 1 else 0 end) as linked_by_many_elements, 
sum( case when (
id_match 
+ verified_phone_match
+ good_user_three_ds_avs_match
+ phone_bin_ip_location_match 
+ low_model_score
) > 1 then 1 else 0 end )as simplex_approve, 
sum(low_mm_riskscore) as low_mm_riskscore


    

 from (
 ;
select p_ids.id as payment_id,
dec.post_auth_reason as reason,  
-- dec.post_auth_decision as a_dec,
-- dec.post_auth_reason as a_reason, 
case when (al.user_label in ('not_approved_user_cancelled_last_payment')) or (al.user_label = 'other' and al.last_state ilike ('%cancelled%')) then ct.cancellation_type
when al.user_label = 'other' then al.last_state
-- else al.user_master_label end as label,
else al.user_label end as label,

case when (variables ->> 'ip_num_users') != 'no_data' and (variables ->> 'ip_num_users')::int > 1 then 1 else 0 end as ip_link,
case when (variables ->> 'cookie_num_users') != 'no_data' and (variables ->> 'cookie_num_users')::int > 1 then 1 else 0 end as cookie_link,
case when (variables ->> 'btc_address_num_users') != 'no_data' and (variables ->> 'btc_address_num_users')::int > 1 then 1 else 0 end as btc_link,
case when (variables ->> 'cc_num_users') != 'no_data' and (variables ->> 'cc_num_users')::int > 1 then 1 else 0 end as cc_link,
case when (variables ->> 'max_num_phone_users') != 'no_data' and (variables ->> 'max_num_phone_users')::int > 1 then 1 else 0 end as phone_link,
case when (variables ->> 'ip_num_users') != 'no_data' and (variables ->> 'ip_num_users')::int < 3 then 1 else 0 end as weak_ip_link,
case when (variables ->> 'cookie_num_users') != 'no_data' and (variables ->> 'cookie_num_users')::int < 3 then 1 else 0 end as weak_cookie_link,
case when (variables ->> 'btc_address_num_users') != 'no_data' and (variables ->> 'btc_address_num_users')::int < 3 then 1 else 0 end as weak_btc_link,
case when (variables ->> 'cc_num_users') != 'no_data' and (variables ->> 'cc_num_users')::int < 3 then 1 else 0 end as weak_cc_link,
case when (variables ->> 'max_num_phone_users') != 'no_data' and (variables ->> 'max_num_phone_users')::int < 3 then 1 else 0 end as weak_phone_link,

case when (variables ->> 'payment_model_score') != 'no_data' and (variables ->> 'payment_model_score')::float < 0.1 then 1 else 0 end as low_model_score,
case when (variables ->> 'mm_riskscore') != 'no_data' and (variables ->> 'mm_riskscore')::float < 5 then 1 else 0 end as low_mm_riskscore,

case when variables ->> 'linked_suspiciously' = 'true' then 1 else 0 end as linked_suspiciously,
case when variables ->> 'id_match' = 'true' then 1 else 0 end as id_match, 
case when variables ->> 'verified_phone_match' = 'true' then 1 else 0 end as verified_phone_match, 
case when variables ->> 'good_user_three_ds_avs_match' = 'true' then 1 else 0 end as good_user_three_ds_avs_match, 
case when variables ->> 'phone_bin_ip_location_match' = 'true' then 1 else 0 end as phone_bin_ip_location_match

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
and variables ->> 'user_previously_reviewed_by_analyst' = 'true'
-- group by 1
;
--  order by 1 desc limit 50
)a  
-- where weak_btc_link = 1

-- and 
-- (
-- id_match 
-- + verified_phone_match
-- + good_user_three_ds_avs_match
-- + phone_bin_ip_location_match 
-- + low_model_score
-- ) = 0 
-- where linked_suspiciously = 1
group by 1
, 2
) b 
where label != 'other'
order by 1, 2 desc
;
select distinct user_label from mv_all_labels;

select * from mv_all_labels where payment_id <  820000 order by 1 desc limit 500;
