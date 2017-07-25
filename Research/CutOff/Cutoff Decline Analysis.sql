with c_decisions as (select payment_id, application_name, decision, variables from decisions where application_name = 'Bender_Pending_Payment_Manual'),

p_info as (
select * from (
select 
al.payment_id, 
p.email, 
al.first_decision, 
pd.cutoff_decision,
pd.cutoff_reason,
last_state, 
user_label, 
case 
when  user_label in ('good_user', 'approved_by_analyst', 'auto_approved') then 'good'
when user_label in ('fraudalent_user', 'urs_decline', 'bad_user') then 'bad'
when user_label in ('auto_declined') then 'auto_declined'
when user_label in ('not_approved_user_cancelled_last_payment', 'approved_user_cancelled_last_payment') then 'cancelled'
else user_label
end  as final_user_label,
case when (cd.variables#>> '{Analytic, variables, Analytic,good_user_three_ds_avs_match}') ='true' then 1 else 0 end as good_user_three_ds_avs_match,
case when (cd.variables#>> '{Analytic, variables, Analytic,id_match}') ='true' then 1 else 0 end as id_match,
case when (cd.variables#>> '{Analytic, variables, Analytic,verified_phone_match}') ='true' then 1 else 0 end as verified_phone_match,
case when (cd.variables#>> '{Analytic, variables, Analytic,phone_bin_ip_location_match}') ='true' then 1 else 0 end as phone_bin_ip_location_match,
case when (cd.variables#>> '{Analytic, variables, Analytic,decent_email_without_alerts}') ='true' and 
coalesce((cd.variables#>> '{Analytic, variables, Analytic,user_emailage}'),(cd.variables#>> '{Analytic, variables, Analytic,buyer_emailage}')) != 'no_data' and 
coalesce((cd.variables#>> '{Analytic, variables, Analytic,user_emailage}'),(cd.variables#>> '{Analytic, variables, Analytic,buyer_emailage}'))::int > 2 then 1 else 0 end as decent_email_without_alerts,
case when (cd.variables#>> '{Analytic, variables, Analytic,user_with_social_media_or_phone_name_match}') ='true' then 1 else 0 end as user_with_social_media_or_phone_name_match,

--Decline Rules
case when (cd.variables#>> '{Analytic, variables, Analytic,linked_suspiciously}') ='true' then 1 else 0 end as linked_suspiciously,
case when (cd.variables#>> '{Analytic, variables, Analytic,user_with_many_bad_indicators}') ='true' then 1 else 0 end as user_with_many_bad_indicators,
case when coalesce ((cd.variables#>> '{Analytic, variables, Analytic,is_proxy_1}'), (cd.variables#>> '{Analytic, variables, Analytic,buyer_proxy}')) ='true' then 1 else 0 end as proxy,
case when coalesce ((cd.variables#>> '{Analytic, variables, Analytic,ip_address_far}'), (cd.variables#>> '{Analytic, variables, Analytic,buyer_ip_address_far}')) ='true' then 1 else 0 end as ip_address_far,
case when (cd.variables#>> '{Analytic, variables, Analytic,linked_to_another_user_2}') ='true' then 1 else 0 end as linked_to_another_user,
case when (cd.variables#>> '{Analytic, variables, Analytic,mm_binmatch}') ='true' then 1 else 0 end as mm_binmatch,
case when (cd.variables#>> '{Analytic, variables, Analytic,fresh_email_with_email_name_match}') ='true' then 1 else 0 end as fresh_email_with_email_name_match



from mv_new_all_labels al
left join ma_view_payment_decisions pd on pd.payment_id = al.payment_id
left join payments p on p.id = al.payment_id
left join c_decisions cd on cd.payment_id = al.payment_id

left join (select payment_id, variables from decisions where application_name = 'Bender_Auto_Decide') d on d.payment_id = al.payment_id 
where 
-- (al.payment_id in (select payment_id from simulator_parameters sp where group_id = 1195)) 
al.payment_id between 410000 and 810000
and (d.variables#>> '{Analytic, variables, Analytic, user_previously_reviewed_by_analyst}') = 'false'
-- and (d.variables#>> '{Analytic, variables, Analytic, risk_mode}') = 'liberal'
-- and pd.post_auth_decision = 'approved' and first_decision = 'auto_approved' 
and pd.cutoff_decision = 'declined' and first_decision = 'cutoff_declined' 
-- and pd.cutoff_decision = 'approved' and first_decision = 'cutoff_approved' 
and user_label not in ('other')
)a

-- where 
-- (
-- good_user_three_ds_avs_match 
-- + id_match 
-- + verified_phone_match 
-- + phone_bin_ip_location_match
-- + decent_email_without_alerts
-- -- + user_with_social_media_or_phone_name_match
-- -- + liberal_risk_mode_approve_mining_user
-- + is_social_media
-- 
-- ) > 0

-- or (low_mm_riskscore = 1 and recent_phone_name_match = 1)
)
,
sums_per_payment as (
select 
distinct 
-- last_state 
final_user_label
as label,

-- first_decision, 
-- cutoff_decision,
-- cutoff_reason,

-- user_label, 



count(distinct payment_id) as num_payments,
sum(linked_suspiciously) as linked_suspiciously,
sum(user_with_many_bad_indicators) as user_with_many_bad_indicators ,
sum(proxy) as proxy ,
sum(ip_address_far) as ip_address_far ,
sum(linked_to_another_user) as linked_to_another_user ,
sum(mm_binmatch) as mm_binmatch,  
sum(fresh_email_with_email_name_match) as fresh_email_with_email_name_match,  



-- user_label 
from p_info 


-- (has_facebook_account = 0 and has_linkedin_account = 0)


group by 1 order by 1,2 desc
)




select 
label, 
-- first_decision,

-- user_label, 

num_payments,  
-- sum(num_payments) over (partition by cutoff_reason) as total_payments,
-- 100*num_payments/sum(num_payments) over (partition by cutoff_reason) as perc_payments
sum(num_payments) over () as total_payments,
100*num_payments/sum(num_payments) over () as perc_payments,
linked_suspiciously, 
sum(linked_suspiciously) over () as total_linked_suspiciously,
100*linked_suspiciously/sum(linked_suspiciously) over () as perc_linked_suspiciously,
user_with_many_bad_indicators, 
sum(user_with_many_bad_indicators) over () as total_user_with_many_bad_indicators,
100*user_with_many_bad_indicators/sum(user_with_many_bad_indicators) over () as perc_user_with_many_bad_indicators,
proxy,
sum(proxy) over () as proxy,
100*proxy/sum(proxy) over () as perc_proxy,
ip_address_far,
sum(ip_address_far) over () as total_ip_address_far,
100*ip_address_far/sum(ip_address_far) over () as perc_ip_address_far,
linked_to_another_user, 
sum(linked_to_another_user) over () as total_linked_to_another_user,
100*linked_to_another_user/sum(linked_to_another_user) over () as perc_linked_to_another_user, 
mm_binmatch, 
sum(mm_binmatch) over () as total_mm_binmatch,
100*mm_binmatch/sum(mm_binmatch) over () as perc_mm_binmatch, 

-- is_social_media, 
-- sum(is_social_media) over () as total_is_social_media,
-- 100*is_social_media/sum(is_social_media) over () as perc_is_social_media
-- recent_phone_name_match, 
-- sum(recent_phone_name_match) over () as total_recent_phone_name_match,
-- 100*recent_phone_name_match/sum(recent_phone_name_match) over () as perc_recent_phone_name_match,
-- has_facebook_account, 
-- sum(has_facebook_account) over () as total_has_facebook_account,
-- 100*has_facebook_account/sum(has_facebook_account) over () as perc_recent_phone_name_match,
-- has_linkedin_account, 
-- sum(has_linkedin_account) over () as total_has_linkedin_account,
-- 100*has_linkedin_account/sum(has_linkedin_account) over () as perc_has_linkedin_account
-- many_ccs, 
-- sum(many_ccs) over () as total_many_ccs,
-- 100*many_ccs/sum(many_ccs) over () as perc_many_ccs
-- num_all,
-- sum(num_all) over () as num_all,
-- 100*num_all/sum(num_all) over () as perc_num_all
-- approve_threeds_liable,
-- sum(approve_threeds_liable) over () as approve_threeds_liable,
-- 100*approve_threeds_liable/sum(approve_threeds_liable) over () as perc_approve_threeds_liable,
-- liberal_risk_mode_approve_mining_user,
-- sum(liberal_risk_mode_approve_mining_user) over () as liberal_risk_mode_approve_mining_user,
-- 100*liberal_risk_mode_approve_mining_user/sum(liberal_risk_mode_approve_mining_user) over () as perc_liberal_risk_mode_approve_mining_user


from  sums_per_payment order by 2 desc;

select * from ma_view_payment_decisions
where cutoff_decision is not null and manual_decision is not null;


