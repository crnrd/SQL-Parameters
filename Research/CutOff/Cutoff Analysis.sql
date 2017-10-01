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
case when (cd.variables#>> '{Analytic, variables, Analytic,user_with_social_media_or_phone_name_match}') ='true' then 1 else 0 end as user_with_social_media_or_phone_name_match,
case when (cd.variables#>> '{Analytic, variables, Analytic,is_social_media_cl}') = 'true' then 1 else 0 end as is_social_media,
case when coalesce((cd.variables#>> '{Analytic, variables, Analytic,has_facebook_account}'), 
(cd.variables#>> '{Analytic, variables, Analytic,buyer_has_facebook_account}')) ='true' then 1 else 0 end as has_facebook_account,
case when coalesce((cd.variables#>> '{Analytic, variables, Analytic,has_linkedin_account}'), 
(cd.variables#>> '{Analytic, variables, Analytic,buyer_has_linkedin_account}')) ='true' then 1 else 0 end as has_linkedin_account,
case when (cd.variables#>> '{Analytic, variables, Analytic,num_user_ccs}') != 'no_data' and
(cd.variables#>> '{Analytic, variables, Analytic,num_user_ccs}')::int > 1 then 1 else 0 end as many_ccs,
case when coalesce((cd.variables#>> '{Analytic, variables, Analytic,user_emailage}'),(cd.variables#>> '{Analytic, variables, Analytic,buyer_emailage}')) != 'no_data' and 
coalesce((cd.variables#>> '{Analytic, variables, Analytic,user_emailage}'),(cd.variables#>> '{Analytic, variables, Analytic,buyer_emailage}'))::int > 120 then 1 else 0 end as old_email, 
case when coalesce((cd.variables#>> '{Analytic, variables, Analytic,mm_riskscore}'),(cd.variables#>> '{Analytic, variables, Analytic,buyer_mm_riskscore}')) != 'no_data' and 
coalesce((cd.variables#>> '{Analytic, variables, Analytic,mm_riskscore}'),(cd.variables#>> '{Analytic, variables, Analytic,buyer_mm_riskscore}'))::float <= 30 then 1 else 0 end as low_mm_riskscore, 
-- 
case when coalesce((cd.variables#>> '{Analytic, variables, Analytic,recent_phone_name_match}'),
(cd.variables#>> '{Analytic, variables, Analytic,buyer_recent_phone_name_match}')) = 'true'  then 1 else 0 end as recent_phone_name_match,
case when (cd.variables#>> '{Analytic, variables, Analytic,decent_email_without_alerts}') ='true' and 
coalesce((cd.variables#>> '{Analytic, variables, Analytic,user_emailage}'),(cd.variables#>> '{Analytic, variables, Analytic,buyer_emailage}')) != 'no_data' and 
coalesce((cd.variables#>> '{Analytic, variables, Analytic,user_emailage}'),(cd.variables#>> '{Analytic, variables, Analytic,buyer_emailage}'))::int > 180 then 1 else 0 end as decent_email_without_alerts,
case when (cd.variables#>> '{Analytic, variables, Analytic,variable_for_random_approve_num_all_low_threshold}') ='true' then 1 else 0 end as num_all,
case when (cd.variables#>> '{Analytic, rules , approve_threeds_liable,decision}') ='approved' then 1 else 0 end as approve_threeds_liable,
case when (cd.variables#>> '{Analytic, rules, liberal_risk_mode_approve_mining_user, decision}') ='approved' then 1 else 0 end as liberal_risk_mode_approve_mining_user, 
-- case when (cd.variables#>> '{Analytic, rules , approve_returning_weak_approve_under_limit,decision}') ='approved' then 1 else 0 end as approve_returning_weak_approve_under_limit,
-- case when (cd.variables#>> '{Analytic, rules, approve_returning_strong_approve_under_limit, decision}') ='approved' then 1 else 0 end as approve_returning_strong_approve_under_limit,
-- case when (cd.variables#>> '{Analytic, rules, approve_verified_card_below_velocity_limits_threeds, decision}') ='approved' then 1 else 0 end as approve_verified_card_below_velocity_limits_threeds, 
case when (cd.variables#>> '{Analytic, rules, liberal_risk_mode_approve_verified_user_with_not_many_ccs_under_limit, decision}') ='approved' then 1 else 0 end as liberal_risk_mode_approve_verified_user_with_not_many_ccs_under_limit
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
-- and pd.cutoff_decision = 'declined' and first_decision = 'cutoff_declined' 
and pd.cutoff_decision = 'approved' and first_decision = 'cutoff_approved' 
and user_label not in ('other')
)a

where 
(
good_user_three_ds_avs_match 
+ id_match 
+ verified_phone_match 
+ phone_bin_ip_location_match
-- + decent_email_without_alerts
-- + user_with_social_media_or_phone_name_match
-- + liberal_risk_mode_approve_mining_user
-- + is_social_media
-- 
) = 0

-- or (low_mm_riskscore = 1 and recent_phone_name_match = 1)
)
,
sums_per_payment as (
select 
distinct 
last_state 
-- final_user_label
as label,

-- first_decision, 
-- cutoff_decision,
-- cutoff_reason,

-- user_label, 



count(distinct payment_id) as num_payments,
sum(good_user_three_ds_avs_match) as good_user_three_ds_avs_match,
sum(id_match) as id_match ,
sum(verified_phone_match) as verified_phone_match ,
sum(phone_bin_ip_location_match) as phone_bin_ip_location_match ,
sum(decent_email_without_alerts) as decent_email_without_alerts ,
sum(case when 
recent_phone_name_match = 1
-- user_with_social_media_or_phone_name_match = 1
 and low_mm_riskscore = 1 
--  and is_social_media = 1
--  and has_facebook_account = 1 and has_linkedin_account = 1 
 then 1 else 0 end) as user_with_social_media_or_phone_name_match,  
sum(is_social_media) as is_social_media,  
sum(has_facebook_account) as has_facebook_account,  
sum(has_linkedin_account) as has_linkedin_account,  
sum(many_ccs) as many_ccs, 
sum(recent_phone_name_match) as recent_phone_name_match, 
sum(num_all) as num_all ,
sum(approve_threeds_liable) as approve_threeds_liable ,
sum(liberal_risk_mode_approve_mining_user) as liberal_risk_mode_approve_mining_user, 
sum(liberal_risk_mode_approve_verified_user_with_not_many_ccs_under_limit) as liberal_risk_mode_approve_verified_user_with_not_many_ccs_under_limit
-- sum(approve_returning_weak_approve_under_limit) as approve_returning_weak_approve_under_limit ,
-- sum(approve_returning_strong_approve_under_limit) as approve_returning_strong_approve_under_limit ,
-- sum(approve_verified_card_below_velocity_limits_threeds) as approve_verified_card_below_velocity_limits_threeds


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

-- sum(good_user_three_ds_avs_match) over () as good_user_three_ds_avs_match,
-- 100*good_user_three_ds_avs_match/sum(good_user_three_ds_avs_match) over () as perc_good_user_three_ds_avs_match,
-- sum(id_match) over () as id_match,
-- 100*id_match/sum(id_match) over () as perc_id_match,
-- sum(verified_phone_match) over () as verified_phone_match,
-- 100*verified_phone_match/sum(verified_phone_match) over () as perc_verified_phone_match,
-- sum(phone_bin_ip_location_match) over () as phone_bin_ip_location_match,
-- 100*phone_bin_ip_location_match/sum(phone_bin_ip_location_match) over () as perc_phone_bin_ip_location_match,
decent_email_without_alerts, 
sum(decent_email_without_alerts) over () as total_decent_email_without_alerts,
100*decent_email_without_alerts/sum(decent_email_without_alerts) over () as perc_decent_email_without_alerts
-- liberal_risk_mode_approve_verified_user_with_not_many_ccs_under_limit, 
-- sum(liberal_risk_mode_approve_verified_user_with_not_many_ccs_under_limit) over () as total_liberal_risk_mode_approve_verified_user_with_not_many_ccs_under_limit
-- 100*liberal_risk_mode_approve_verified_user_with_not_many_ccs_under_limit/sum(liberal_risk_mode_approve_verified_user_with_not_many_ccs_under_limit) over () as perc_liberal_risk_mode_approve_verified_user_with_not_many_ccs_under_limit
-- user_with_social_media_or_phone_name_match, 
-- sum(user_with_social_media_or_phone_name_match) over () as total_user_with_social_media_or_phone_name_match,
-- 100*user_with_social_media_or_phone_name_match/sum(user_with_social_media_or_phone_name_match) over () as perc_user_with_social_media_or_phone_name_match
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


