with velocity_counters as 
(select p.id as payment_id, p.created_at, credit_card, email, (simplex_login ->> 'ip') as ip,

case when ip_bin_num_payments_baseline = 'no_data' then null else ip_bin_num_payments_baseline::float end as ip_bin_num_payments_baseline, 
case when ip_bin_num_emails_baseline = 'no_data' then null else ip_bin_num_emails_baseline::float end as ip_bin_num_emails_baseline, 
case when ip_bin_num_failed_auths_baseline = 'no_data' then null else ip_bin_num_failed_auths_baseline::float end as ip_bin_num_failed_auths_baseline,
case when ip_bin_num_failed_auths_last_10_mins = 'no_data' then null else ip_bin_num_failed_auths_last_10_mins::float end as ip_bin_num_failed_auths_last_10_mins,
case when ip_bin_num_failed_auths_last_30_mins = 'no_data' then null else ip_bin_num_failed_auths_last_30_mins::float end as ip_bin_num_failed_auths_last_30_mins,
case when ip_bin_num_failed_auths_last_1_hour = 'no_data' then null else ip_bin_num_failed_auths_last_1_hour::float end as ip_bin_num_failed_auths_last_1_hour,
case when ip_bin_num_failed_auths_last_4_hours = 'no_data' then null else ip_bin_num_failed_auths_last_4_hours::float end as ip_bin_num_failed_auths_last_4_hours,
case when ip_bin_num_failed_auths_last_12_hours = 'no_data' then null else ip_bin_num_failed_auths_last_12_hours::float end as ip_bin_num_failed_auths_last_12_hours,
case when ip_bin_num_failed_auths_last_24_hours = 'no_data' then null else ip_bin_num_failed_auths_last_24_hours::float end as ip_bin_num_failed_auths_last_24_hours,
case when ip_bin_num_failed_auths_last_36_hours = 'no_data' then null else ip_bin_num_failed_auths_last_36_hours::float end as ip_bin_num_failed_auths_last_36_hours,
case when ip_bin_num_failed_auths_last_72_hours = 'no_data' then null else ip_bin_num_failed_auths_last_72_hours::float end as ip_bin_num_failed_auths_last_72_hours,
case when ip_bin_num_failed_auths_last_7_days = 'no_data' then null else ip_bin_num_failed_auths_last_7_days::float end as ip_bin_num_failed_auths_last_7_days,
case when ip_bin_ratio_failed_auths_last_10_mins_and_baseline = 'no_data' then null else ip_bin_ratio_failed_auths_last_10_mins_and_baseline::float end as ip_bin_ratio_failed_auths_last_10_mins_and_baseline,
case when ip_bin_ratio_failed_auths_last_30_mins_and_baseline = 'no_data' then null else ip_bin_ratio_failed_auths_last_30_mins_and_baseline::float end as ip_bin_ratio_failed_auths_last_30_mins_and_baseline,
case when ip_bin_ratio_failed_auths_last_1_hour_and_baseline = 'no_data' then null else ip_bin_ratio_failed_auths_last_1_hour_and_baseline::float end as ip_bin_ratio_failed_auths_last_1_hour_and_baseline,
case when ip_bin_ratio_failed_auths_last_4_hours_and_baseline = 'no_data' then null else ip_bin_ratio_failed_auths_last_4_hours_and_baseline::float end as ip_bin_ratio_failed_auths_last_4_hours_and_baseline,
case when ip_bin_ratio_failed_auths_last_12_hours_and_baseline = 'no_data' then null else ip_bin_ratio_failed_auths_last_12_hours_and_baseline::float end as ip_bin_ratio_failed_auths_last_12_hours_and_baseline,
case when ip_bin_ratio_failed_auths_last_24_hours_and_baseline = 'no_data' then null else ip_bin_ratio_failed_auths_last_24_hours_and_baseline::float end as ip_bin_ratio_failed_auths_last_24_hours_and_baseline,
case when ip_bin_ratio_failed_auths_last_36_hours_and_baseline = 'no_data' then null else ip_bin_ratio_failed_auths_last_36_hours_and_baseline::float end as ip_bin_ratio_failed_auths_last_36_hours_and_baseline,
case when ip_bin_ratio_failed_auths_last_72_hours_and_baseline = 'no_data' then null else ip_bin_ratio_failed_auths_last_72_hours_and_baseline::float end as ip_bin_ratio_failed_auths_last_72_hours_and_baseline,
case when ip_bin_ratio_failed_auths_last_7_days_and_baseline = 'no_data' then null else ip_bin_ratio_failed_auths_last_7_days_and_baseline::float end as ip_bin_ratio_failed_auths_last_7_days_and_baseline

FROM r_payments rp, payments p, velocity_full_sim_max v
WHERE rp.id = v.payment_id AND rp.simplex_payment_id = p.id 

),

labels as (select mv_all_labels.* from mv_all_labels , velocity_counters where mv_all_labels.payment_id = velocity_counters.payment_id), 

sim as (select rp.simplex_payment_id as payment_id,
 decision,
 reason,
 variables 
 from simulator_results sr
 join  simulator_parameters sp on sr.parameter_id = sp.id 
 join  r_payments rp  on  rp.id = sp.payment_id
where
run_id = 4189)


select l.user_master_label, vc.*, eb.bin_country, em.ip_country



 from velocity_counters vc
 join labels l on vc.payment_id = l.payment_id
 join (select distinct  bin, response_data #>> '{country, alpha2}' as bin_country  
 from enrich_binlist group by 1, 2) as eb on eb.bin = substring(vc.credit_card from 1 for 6)
 JOIN (select distinct (request_data ->> 'i') as ip, (data ->> 'countryCode') as ip_country from enrich_maxmind group by 1,2) as em on em.ip = vc.ip
 
where 
  (ip_bin_num_failed_auths_baseline between 5 and 200)
 and
  ip_bin_num_failed_auths_last_24_hours > 2

   

order by

    ip_bin_ratio_failed_auths_last_4_hours_and_baseline desc,
    ip_bin_ratio_failed_auths_last_12_hours_and_baseline desc,
    ip_bin_ratio_failed_auths_last_24_hours_and_baseline desc,
    ip_bin_ratio_failed_auths_last_36_hours_and_baseline desc,
    ip_bin_ratio_failed_auths_last_72_hours_and_baseline desc,
    ip_bin_ratio_failed_auths_last_7_days_and_baseline desc,
    ip_bin_num_failed_auths_last_1_hour desc,
    ip_bin_num_failed_auths_last_4_hours desc,
    ip_bin_num_failed_auths_last_12_hours desc,
    ip_bin_num_failed_auths_last_24_hours desc,
    ip_bin_num_failed_auths_last_36_hours desc,
    ip_bin_num_failed_auths_last_72_hours desc
   
limit 50   
    
 ;
