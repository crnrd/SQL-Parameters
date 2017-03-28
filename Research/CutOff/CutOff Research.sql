with zach_label as 
--Zach's label
--labels payments as 'Bad', 'Good', or 'Cancelled'

(select id, label zachs_label from (
select id, status, chargeback_at,
case when status = 15 or (chargeback_at is not null and chargeback_reason::varchar  in ('4837', '4870', '6341', '6321', '83', '75', '33'))  then 'Fraud Chargeback'--'Bad'
when chargeback_at is not null then 'Service Chargeback'     
when status in (2,13) then 'Good'
     when status = 16 or (status = 11 and id in (select payment_id from decisions where application_name = 'Manual'  and decision = 'declined' 
                     and variables#>> '{strength}' = 'Weak' 
                     and reason != 'Bad Indicators, Unable to send Verification'
                     and reason != 'Other'
                     order by payment_id desc)) 
             then 'Cancelled'
     when status = 11 then 'Bad'      
end "label"
from payments where id in (select id from payments where id>17000)
)a),

simulator_results as (select sp.*, sr.* from simulator_results sr left join simulator_parameters sp
 on sp.id = sr.parameter_id
 where    sr.run_id = 2661)
 
select distinct reason, decision,
sum(case when zachs_label = 'Bad' then perc else 0 end ) as bad_perc,
sum(case when zachs_label = 'Cancelled' then perc else 0 end) as Cancelled_perc ,
sum(case when zachs_label = 'Fraud Chargeback' then perc else 0 end) as fraud_cb_perc ,
sum(case when zachs_label = 'Service Chargeback' then perc else 0 end) as service_cb_perc ,
sum(case when zachs_label = 'Good' then perc else 0 end) as good_perc ,
sum(num_payments)from(
select reason, zachs_label, decision, num_payments, 
-- sum(case when zachs_label = 'Bad' then num_payments else 0 end ) as bad_payments 
100*num_payments/sum(num_payments)
over (partition by reason) as perc from (
select distinct reason, zachs_label, decision,  count(distinct payment_id) as num_payments from simulator_results sr
left join 
zach_label zl on zl.id = sr.payment_id
where 
-- (sr.variables#>> '{Analytic,risk_mode}') = 'liberal' 
-- and ((reason ilike 'returning % user over limit 1' 
-- and decision = 'verify') or  (reason ilike 'verified card breached velocity limits during last day/week/month' and decision ='manual'))
(sr.variables#>> '{Analytic, user_previously_reviewed_by_analyst}') = 'false'
-- and (sr.variables#>> '{Analytic, emailage_bad_reason}') = 'true'


--  and (sr.variables#>> '{Analytic, num_user_phones}')::int > 2
-- and
-- and
-- 
and
 (sr.variables#>> '{Analytic, num_new_ccs_since_last_manually_approved_payment}')::int > 2
 and
  (sr.variables#>> '{Analytic, num_names_on_cards}')::int > 1
--  and
 
-- --  (sr.variables#>> '{Analytic, num_user_ccs}')::int > and
-- and  (sr.variables#>> '{Analytic, num_all}') != 'no_data' and
--  (sr.variables#>> '{Analytic, num_all}')::float > 0.75
-- and 
-- (sr.variables#>> '{Analytic, mm_riskscore}') != 'no_data' 
-- and (sr.variables#>> '{Analytic, mm_riskscore}')::float < 0.5
-- and
-- and
--  ( 
-- (sr.variables#>> '{Analytic, id_match_1}') = 'true' or
-- (sr.variables#>> '{Analytic, good_user_three_ds_avs_match}') = 'true' or
-- (sr.variables#>> '{Analytic, verified_phone_match}') = 'true' or
-- (sr.variables#>> '{Analytic, phone_bin_ip_location_match}') = 'true' 
-- 
-- )
and decision in ('manual'
-- , 'verify'
)

-- and decision = 'manual' 
group by 1,2,3
order by 1,2,3,4
)a 
 )b group by 1,2
 ;
select * from simulator_runs order by id desc limit 100;





















with 

zach_label as 
--Zach's label
--labels payments as 'Bad', 'Good', or 'Cancelled'

(select id, label from (
select id, status, chargeback_at,
case when status = 15 or (chargeback_at is not null and chargeback_reason::varchar  in ('4837', '4870', '6341', '6321', '83', '75', '33'))  then 'Fraud Chargeback'--'Bad'
when chargeback_at is not null then 'Service Chargeback'     
when status in (2,13) then 'Good'
     when status = 16 or (status = 11 and id in (select payment_id from decisions where application_name = 'Manual'  and decision = 'declined' 
                     and variables#>> '{strength}' = 'Weak' 
                     and reason != 'Bad Indicators, Unable to send Verification'
                     and reason != 'Other'
                     order by payment_id desc)) 
             then 'Cancelled'
     when status = 11 then 'Bad'      
end "label"
from payments where id in (select id from payments where id>17000)
)a),

simulator_results as (select sp.*, sr.* from simulator_results sr left join simulator_parameters sp
 on sp.id = sr.parameter_id
 where    sr.run_id = 2661),
 
user_label as (with rulling as 
((SELECT payment_id,
                                             application_name,
                                             max_id AS ruling_id,
                                             decision,
                                             reason,
                                             strength,
                                             user_risk_status
                                      FROM (SELECT *
                                            FROM (SELECT *,
                                                         MAX(id) OVER (PARTITION BY payment_id,application_id) max_id,
                                                         MAX(application_id) OVER (PARTITION BY payment_id) max_application_id
                                                  FROM (SELECT d.payment_id,
                                                               d.id,
                                                               d.application_name,
                                                               d.analytic_code_version,
                                                               d.decision,
                                                               d.reason,
                                                               seu.user_risk_status,
                                                               d.variables#>> '{strength}' strength,
                                                               CASE
                                                                 WHEN d.application_name IN ('EndUser','Scheduler') THEN 6
                                                                 WHEN d.application_name = 'Manual' THEN 5
                                                                 WHEN d.application_name = 'Bender_Auto_Decide' AND d.analytic_code_version IS NOT NULL THEN 4
                                                                 WHEN d.application_name = 'Bender_Auto_Decide' THEN 3
                                                                 WHEN d.application_name = 'Bender' THEN 2
                                                                 ELSE 1
                                                               END application_id
                                                        FROM decisions d
                                                          JOIN payments p ON p.id = d.payment_id
                                                           JOIN simplex_end_users seu ON seu.id = p.simplex_end_user_id
                                                        WHERE d.application_name NOT IN ('Challenger','Nibbler_Challenger')
                                                        
-- You can add some arguments here, possibly like this (this will imporve runing time):
-- and where d.payment_id in (****add something****)
                                                        GROUP BY 1,
                                                                 2,
                                                                 3,
                                                                 4,
                                                                 5,
                                                                 6,
                                                                 seu.user_risk_status,
                                                                 8) a) b
                                            WHERE max_application_id = application_id
                                            AND   id = max_id) h
                                      ORDER BY payment_id ASC))
                                     



SELECT simplex_end_user_id,
       new_labeling as label,
--        last_decision_id,
--        first_decision_id,
       p_id as id
--        p_status,
--        max_approve_id,
--        max_decline_cancel_id,
--        tx_per_user,
--        decline_sum,
--        cancel_sum,
--        decline_count,
--        cancel_count,
--        application_name,
--        ruling_id,
--        decision,
--        reason,
--               user_risk_status,
--        strength,
--        handling_at,
--        chargeback_at,
--        chargeback_reason,
--        good_marker1,
--        bad_marker1,
--        cb_f_marker,
--        cb_marker,
--        cb_f_user,
--        cb_user,
--        good_user,
--        bad_user,
--        weak_approve
FROM (SELECT *,
             CASE
               WHEN (cb_f_user = '1') OR (bad_user = '1') THEN 'Bad'
               WHEN cb_user = '1' THEN 'Undefined_cb_user'
               WHEN good_user = '1' THEN 'Good'
               WHEN cancel_sum = tx_per_user THEN 'Unknown'
               WHEN weak_approve = '1' THEN 'Weak Good'
               ELSE 'no_data'
             END new_labeling
      FROM (SELECT *,
                   MAX(cb_f_marker) OVER (PARTITION BY simplex_end_user_id) cb_f_user,
                   MAX(cb_marker) OVER (PARTITION BY simplex_end_user_id) cb_user,
                   --marks all payment made by the user as chargeback-user
                   MAX(good_marker1) OVER (PARTITION BY simplex_end_user_id) AS good_user,
                   --marks all payment made by the user as good-user
                   MAX(bad_marker1) OVER (PARTITION BY simplex_end_user_id) AS bad_user
            FROM
            --marks all payment made by the user as good-user
            (SELECT *,
                    CASE
                      WHEN ((decline_sum > 0 OR cancel_sum > 0) AND last_decision_id = p_id AND p_status = 2) OR (decline_sum = 0 AND cancel_sum = 0 AND tx_per_user > 1) OR (tx_per_user = 1 AND p_status = 2 AND EXTRACT(DAY FROM NOW() - handling_at) > 100) OR ((decline_sum > 0 OR cancel_sum > 0) AND p_status = 2 AND application_name = 'Manual' AND p_id > max_decline_cancel_id) OR (decline_sum = 0 AND cancel_sum > 0 AND p_id = max_approve_id AND EXTRACT(DAY FROM NOW() - handling_at) > 100) OR (tx_per_user = 1 AND p_status = 2 AND strength = 'Strong')
             --user with 1 payment who had strong approve
             THEN '1'
                    END good_marker1,
                    --marks individual payments as good indicator for the user
                    CASE
                      WHEN (last_decision_id = p_id AND decline_count = 1 AND tx_per_user > 1) OR (decline_sum + cancel_sum = tx_per_user AND decline_sum > 0) OR (cast(user_risk_status as varchar) ilike '%decline%') THEN '1'
                    END bad_marker1,
                    --marks individual payments as bad indicator for the user
                    CASE
                      WHEN (chargeback_at IS NOT NULL AND chargeback_reason ilike '%Fraud%') OR (p_status = 15) THEN '1'
                    END cb_f_marker,
                    CASE
                      WHEN chargeback_at IS NOT NULL AND (chargeback_reason NOT ilike '%Fraud%' OR chargeback_reason IS NULL) THEN '1'
                    END cb_marker,
                    CASE
                      WHEN (tx_per_user = 1 AND strength = 'Weak') OR (tx_per_user = 1 AND application_name = 'Bender_Auto_Decide') THEN '1'
                    END weak_approve
             FROM (SELECT SUM(decline_count) OVER (PARTITION BY simplex_end_user_id) AS decline_sum,
                          SUM(cancel_count) OVER (PARTITION BY simplex_end_user_id) AS cancel_sum,
                          MAX(CASE WHEN (decline_count = 1 OR cancel_count = 1) THEN p_id END) OVER (PARTITION BY simplex_end_user_id) AS max_decline_cancel_id,
                          MAX(CASE WHEN p_status = 2 THEN p_id END) OVER (PARTITION BY simplex_end_user_id) AS max_approve_id,
                          MAX(p_id) OVER (PARTITION BY simplex_end_user_id) AS last_decision_id,
                          MIN(p_id) OVER (PARTITION BY simplex_end_user_id) AS first_decision_id,
                          *
                   FROM (SELECT p.id p_id,
                                p.simplex_end_user_id,
                                p.status p_status,
                                CASE
                                  WHEN p.status IN (11) AND (strength = 'Strong' OR (strength = 'Weak' AND reason ilike '%Other%') OR application_name ilike '%Bender%') THEN 1
                                  ELSE 0
                                END decline_count,
                                CASE
                                  WHEN (p.status IN (16,18,22,23)) OR (p.status = 11 AND strength = 'Weak' AND reason NOT ilike '%Other%') THEN 1
                                  ELSE 0
                                END cancel_count,
                                rulling.application_name,
                                ruling_id,
                                rulling.decision,
                                rulling.reason,
                                rulling.strength,
                                rulling.user_risk_status,
                                COUNT(*) OVER (PARTITION BY p.simplex_end_user_id) tx_per_user,
                                p.handling_at,
                                p.chargeback_at,
                                p.chargeback_reason
                         FROM payments p
                           LEFT JOIN  rulling ON p.id = rulling.payment_id
                         WHERE rulling.payment_id >= 8847
                         AND   p.status NOT IN (0,1,19,6,20,23)) c) d) e) f) g where p_id in (select payment_id from simulator_results))
 

 



select label,
-- Total Payments
100*total_payments/sum(total_payments) over () as total_payments,
sum(total_payments) over () as total_payments_total,



-- Approval Rule Candidate
--  100*approval_rule/sum(approval_rule) over () as approval_rule,
-- sum(approval_rule) over () as approval_rule_total,
-- 
--  100*no_bad_external_indicators/sum(no_bad_external_indicators) over () as no_bad_external_indicators,
-- sum(no_bad_external_indicators) over () as no_bad_external_indicators_total,
-- 
--  100*would_have_been_approved_by_simplex/sum(would_have_been_approved_by_simplex) over () as would_have_been_approved_by_simplex,
--   sum(would_have_been_approved_by_simplex) over () as would_have_been_approved_by_simplex_total,
--   
--  100*external_social_data/sum(external_social_data) over () as external_social_data,
--  sum(external_social_data) over () as external_social_data_total,
-- 100*old_email/sum(old_email) over () as old_email,
-- sum(old_email) over () as old_email_total


-- Decline Rule Candidate
-- 100*bad_linking/sum(bad_linking) over () as bad_linking,
-- sum(bad_linking) over () as bad_linking_total,
-- 100*proxy_far_address/sum(proxy_far_address) over () as proxy_far_address,
-- sum(proxy_far_address) over () as proxy_far_address_total,


-- 
100*bad_indictors_no_proxy/sum(bad_indictors_no_proxy) over () as bad_indictors_no_proxy,
sum(bad_indictors_no_proxy) over () as bad_indictors_no_proxy


  from (
select distinct label, 
sum(case when would_have_been_approved_by_simplex = 1 or external_social_data = 1 or old_email = 1 or avs_match_with_few_cards = 1 or 
no_bad_external_indicators = 1 then 1 else 0 end)  as approval_rule,
sum(no_bad_external_indicators)  as no_bad_external_indicators,
sum(would_have_been_approved_by_simplex)  as would_have_been_approved_by_simplex,
sum(external_social_data)  as external_social_data,
count(*) as total_payments, 
sum(many_cards_and_info_change)  as many_cards_and_info_change,
sum(case when bad_indictors_no_proxy = 1  then 1 else 0 end) as bad_indictors_no_proxy,
sum(case when old_email = 1  then 1 else 0 end) as old_email,
sum(case when proxy_far_address = 1  then 1 else 0 end) as proxy_far_address,
sum(case when bad_linking = 1  then 1 else 0 end) as bad_linking

from (

select label,

-- good indicators
case when (low_mm_riskscore = 1 and low_num_all = 1 and high_emailage_score = 0 )then 1 else 0 end as no_bad_external_indicators ,
case when  (id_match_1 = 1 or phone_bin_ip_location_match = 1 or good_user_for_non_three_ds = 1 or verified_phone_match = 1) then 1 else 0 end as would_have_been_approved_by_simplex,
case when  (has_facebook_account = 1 or has_linkedin_account = 1 or recent_phone_name_match = 1 or is_social_media = 1) then 1 else 0 end as external_social_data,
case when old_email = 1  then 1 else 0 end as old_email, 
name_on_card_mismatch, 
avs_match, 
avs_match_with_few_cards, 
was_auth_done_with_threeds,
linked_to_another_user,
low_num_all,
mining_payment,
email_name_match,
high_mm_riskscore,
-- bad indicators
case when
 emailage_bad_reason = 1
    
then 1 else 0 end as many_cards_and_info_change,

case when (linked_by_cookie + linked_by_btc + linked_by_cc + linked_by_ip + linked_by_phone) > 0 then 1 else 0 end as bad_linking, 

case when (email_name_match
 )
 >= 0  then 1 else 0 end as bad_indictors_no_proxy,
 
case when (is_proxy + ip_address_far + unverified_phone + phone_country_mismatch + bin_mismatch  ) > 0 then 1 else 0 end proxy_far_address
-- sum(low_mm_riskscore)as low_mm_riskscore, 
-- sum(high_mm_riskscore) as high_mm_riskscore,
-- sum(low_num_all) as low_num_all,
-- sum(high_num_all) as high_num_all,
-- sum(emailage_bad_reason) as emailage_bad_reason,
-- sum(ip_address_far) as ip_address_far,
-- sum(many_addresses) as many_addresses,
-- sum(is_proxy) as is_proxy,
-- sum(high_emailage_score) as high_emailage_score,
-- sum(many_names_on_card) as many_names_on_card,
-- sum(unverified_phone) as unverified_phone,
-- sum(name_on_card_mismatch) as name_on_card_mismatch,
-- sum(many_phones) as many_phones,
-- sum(many_cards) as many_cards,
-- sum(new_email) as new_email,
-- 
-- -- good vars
-- sum(id_match_1) as id_match_1,
-- sum(good_user_for_non_three_ds) as good_user_for_non_three_ds,
-- sum(has_facebook_account) as has_facebook_account,
-- sum(has_linkedin_account) as has_linkedin_account,
-- sum(high_mm_riskscore) as verified_phone_match,
-- sum(phone_bin_ip_location_match) as phone_bin_ip_location_match,
-- sum(recent_phone_name_match) as recent_phone_name_match
from (
select label, decision, reason, 

--bad vars
case when (sr.variables#>> '{Analytic,mm_riskscore}') !='no_data' and (sr.variables#>> '{Analytic,mm_riskscore}')::float < 0.5 then 1 else 0 end as low_mm_riskscore,
case when (sr.variables#>> '{Analytic,mm_riskscore}') !='no_data' and (sr.variables#>> '{Analytic,mm_riskscore}')::float >  70 then 1 else 0 end as high_mm_riskscore,
case when (sr.variables#>> '{Analytic,num_all}') !='no_data' and (sr.variables#>> '{Analytic,num_all}')::float < 0.5 then 1 else 0 end as low_num_all,
case when (sr.variables#>> '{Analytic,num_all}') !='no_data' and (sr.variables#>> '{Analytic,num_all}')::float > 0.8 then 1 else 0 end as high_num_all,
case when (sr.variables#>> '{Analytic,emailage_bad_reason}') ='true' then 1 else 0 end as emailage_bad_reason,
case when (sr.variables#>> '{Analytic,ip_address_far}') ='true' then 1 else 0 end as ip_address_far,


case when (sr.variables#>> '{Analytic,linked_to_another_user}') ='true' then 1 else 0 end as linked_to_another_user,
case when (sr.variables#>> '{Analytic,cookie_num_users}')::int > 3 then 1 else 0 end as linked_by_cookie,
case when (sr.variables#>> '{Analytic,btc_address_num_users}')::int > 2  then 1 else 0 end as linked_by_btc,
case when (sr.variables#>> '{Analytic,cc_num_users}')::int > 3 then 1 else 0 end as linked_by_cc,
case when (sr.variables#>> '{Analytic,ip_num_users}')::int > 2 then 1 else 0 end as linked_by_ip,
case when (sr.variables#>> '{Analytic,max_num_phone_users}')::int > 2 then 1 else 0 end as linked_by_phone,

case when (sr.variables#>> '{Analytic,user_num_addresses}')::int > 1 then 1 else 0 end as many_addresses,
case when (sr.variables#>> '{Analytic,num_names_on_cards}')::int > 2 then 1 else 0 end as many_names_on_card,
case when (sr.variables#>> '{Analytic,num_user_ccs}')::int >2 then 1 else 0 end as many_cards,
case when (sr.variables#>> '{Analytic,is_proxy}') ='true' then 1 else 0 end as is_proxy,
case when (sr.variables#>> '{Analytic,ea_score}') !='no_data' and  (sr.variables#>> '{Analytic,ea_score}')::int > 600 then 1 else 0 end as high_emailage_score,
case when (sr.variables#>> '{Analytic,phone_country_match}') ='false' then 1 else 0 end as phone_country_mismatch,
case when (sr.variables#>> '{Analytic,verified_phone}') ='false' then 1 else 0 end as unverified_phone,
case when (sr.variables#>> '{Analytic,name_on_card_match}') ='no_match' then 1 else 0 end as name_on_card_mismatch,
case when (sr.variables#>> '{Analytic,mm_binmatch}')  = 'Yes' then 0 else 1 end as bin_mismatch,
case when (sr.variables#>> '{Analytic,num_bin_countries}')::int> 1 then 1 else 0 end as many_bins,
case when (sr.variables#>> '{Analytic,num_user_phones}')::int > 4 then 1 else 0 end as many_phones,

case when (sr.variables#>> '{Analytic,user_emailage}') !='no_data' and (sr.variables#>> '{Analytic,user_emailage}')::int < 30 then 1 else 0 end as new_email,
case when (sr.variables#>> '{Analytic,user_emailage}') !='no_data' and (sr.variables#>> '{Analytic,user_emailage}')::int > 1 then 1 else 0 end as old_email,
--good vars
case when (sr.variables#>> '{Analytic,id_match_1}') ='true' then 1 else 0 end as id_match_1,
case when (sr.variables#>> '{Analytic,good_user_for_non_three_ds}') ='true' then 1 else 0 end as good_user_for_non_three_ds,
case when (sr.variables#>> '{Analytic,has_facebook_account}') ='true' then 1 else 0 end as has_facebook_account,
case when (sr.variables#>> '{Analytic,has_linkedin_account}') ='true' then 1 else 0 end as has_linkedin_account,
case when (sr.variables#>> '{Analytic,verified_phone_match}') ='true' then 1 else 0 end as verified_phone_match,
case when (sr.variables#>> '{Analytic,phone_bin_ip_location_match}') ='true' then 1 else 0 end as phone_bin_ip_location_match,
case when (sr.variables#>> '{Analytic,recent_phone_name_match}') ='true' then 1 else 0 end as recent_phone_name_match,
case when (sr.variables#>> '{Analytic,avs_match}') in ('full_match', 'partial_match') then 1 else 0 end as avs_match,
case when (sr.variables#>> '{Analytic,num_ccs_with_avs_match_to_current_address}')::int > 1  then 1 else 0 end as avs_match_with_few_cards,
case when (sr.variables#>> '{Analytic,was_auth_done_with_threeds}') = 'true'  then 1 else 0 end as was_auth_done_with_threeds,
case when (sr.variables#>> '{Analytic,is_social_media}') = 'true'  then 1 else 0 end as is_social_media,
case when (sr.variables#>> '{Analytic,email_name_match_score}')::float > 0.7 then 1 else 0 end as email_name_match,
case when (sr.variables#>> '{Analytic,partner_type}') = 'mining_pool' then 1 else 0 end as mining_payment






--  count(distinct payment_id) as num_payments 
 from simulator_results sr
left join 
zach_label zl on zl.id = sr.payment_id

where 

(sr.variables#>> '{Analytic, user_previously_reviewed_by_analyst}') = 'false'
-- and (sr.variables#>> '{Analytic, linked_to_another_user}') = 'false'

and 
decision in ('manual'
-- , 'verify'
)
and reason not in ('returning user last payment refund', 'manual user risk status',
 'another pending payment', 'nonfraud chargeback reason', 'kyc missing above limit for specific partner')
-- and decision = 'manual' 

)a  )b 
where 
(name_on_card_mismatch = 0 and bad_linking = 0) and 
(
would_have_been_approved_by_simplex = 0
and
  external_social_data = 0
and
no_bad_external_indicators = 0
and
old_email = 0)
and mining_payment = 0
and was_auth_done_with_threeds = 0 
and email_name_match = 0 
-- -- and 
-- --  bad_indictors_no_proxy = 0
-- --  or (
and 
 proxy_far_address = 0
-- and many_cards_and_info_change = 1
 group by 1 order by  1, 2   desc) c

 ;
