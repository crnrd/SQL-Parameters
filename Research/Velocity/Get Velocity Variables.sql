select distinct user_label, count(*) from (
select p_id, group_id, payment_id, created_at, status,  time_point, decision, reason, user_label,

case when (variables ->> 'ip_bin_num_payments_baseline') = 'no_data' then null else (variables ->> 'ip_bin_num_payments_baseline')::float end as ip_bin_num_payments_baseline,
case when (variables ->> 'ip_bin_num_payments_last_10_mins') = 'no_data' then null else (variables ->> 'ip_bin_num_payments_last_10_mins')::float end as ip_bin_num_payments_last_10_mins,
case when (variables ->> 'ip_bin_num_payments_last_30_mins') = 'no_data' then null else (variables ->> 'ip_bin_num_payments_last_30_mins')::float end as ip_bin_num_payments_last_30_mins,
case when (variables ->> 'ip_bin_num_payments_last_1_hour') = 'no_data' then null else (variables ->> 'ip_bin_num_payments_last_1_hour')::float end as ip_bin_num_payments_last_1_hour,
case when (variables ->> 'ip_bin_num_payments_last_4_hours') = 'no_data' then null else (variables ->> 'ip_bin_num_payments_last_4_hours')::float end as ip_bin_num_payments_last_4_hours,
case when (variables ->> 'ip_bin_num_payments_last_12_hours') = 'no_data' then null else (variables ->> 'ip_bin_num_payments_last_12_hours')::float end as ip_bin_num_payments_last_12_hours,
case when (variables ->> 'ip_bin_num_payments_last_24_hours') = 'no_data' then null else (variables ->> 'ip_bin_num_payments_last_24_hours')::float end as ip_bin_num_payments_last_24_hours,
case when (variables ->> 'ip_bin_num_payments_last_36_hours') = 'no_data' then null else (variables ->> 'ip_bin_num_payments_last_36_hours')::float end as ip_bin_num_payments_last_36_hours,
case when (variables ->> 'ip_bin_num_payments_last_72_hours') = 'no_data' then null else (variables ->> 'ip_bin_num_payments_last_72_hours')::float end as ip_bin_num_payments_last_72_hours,
case when (variables ->> 'ip_bin_num_payments_last_7_days') = 'no_data' then null else (variables ->> 'ip_bin_num_payments_last_7_days')::float end as ip_bin_num_payments_last_7_days,
case when (variables ->> 'ip_bin_ratio_payments_last_10_mins_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_payments_last_10_mins_and_baseline')::float end as ip_bin_ratio_payments_last_10_mins_and_baseline,
case when (variables ->> 'ip_bin_ratio_payments_last_30_mins_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_payments_last_30_mins_and_baseline')::float end as ip_bin_ratio_payments_last_30_mins_and_baseline,
case when (variables ->> 'ip_bin_ratio_payments_last_1_hour_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_payments_last_1_hour_and_baseline')::float end as ip_bin_ratio_payments_last_1_hour_and_baseline,
case when (variables ->> 'ip_bin_ratio_payments_last_4_hours_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_payments_last_4_hours_and_baseline')::float end as ip_bin_ratio_payments_last_4_hours_and_baseline,
case when (variables ->> 'ip_bin_ratio_payments_last_12_hours_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_payments_last_12_hours_and_baseline')::float end as ip_bin_ratio_payments_last_12_hours_and_baseline,
case when (variables ->> 'ip_bin_ratio_payments_last_24_hours_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_payments_last_24_hours_and_baseline')::float end as ip_bin_ratio_payments_last_24_hours_and_baseline,
case when (variables ->> 'ip_bin_ratio_payments_last_36_hours_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_payments_last_36_hours_and_baseline')::float end as ip_bin_ratio_payments_last_36_hours_and_baseline,
case when (variables ->> 'ip_bin_ratio_payments_last_72_hours_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_payments_last_72_hours_and_baseline')::float end as ip_bin_ratio_payments_last_72_hours_and_baseline,
case when (variables ->> 'ip_bin_ratio_payments_last_7_days_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_payments_last_7_days_and_baseline')::float end as ip_bin_ratio_payments_last_7_days_and_baseline,
case when (variables ->> 'ip_bin_num_emails_baseline') = 'no_data' then null else (variables ->> 'ip_bin_num_emails_baseline')::float end as ip_bin_num_emails_baseline,
case when (variables ->> 'ip_bin_num_emails_last_10_mins') = 'no_data' then null else (variables ->> 'ip_bin_num_emails_last_10_mins')::float end as ip_bin_num_emails_last_10_mins,
case when (variables ->> 'ip_bin_num_emails_last_30_mins') = 'no_data' then null else (variables ->> 'ip_bin_num_emails_last_30_mins')::float end as ip_bin_num_emails_last_30_mins,
case when (variables ->> 'ip_bin_num_emails_last_1_hour') = 'no_data' then null else (variables ->> 'ip_bin_num_emails_last_1_hour')::float end as ip_bin_num_emails_last_1_hour,
case when (variables ->> 'ip_bin_num_emails_last_4_hours') = 'no_data' then null else (variables ->> 'ip_bin_num_emails_last_4_hours')::float end as ip_bin_num_emails_last_4_hours,
case when (variables ->> 'ip_bin_num_emails_last_12_hours') = 'no_data' then null else (variables ->> 'ip_bin_num_emails_last_12_hours')::float end as ip_bin_num_emails_last_12_hours,
case when (variables ->> 'ip_bin_num_emails_last_24_hours') = 'no_data' then null else (variables ->> 'ip_bin_num_emails_last_24_hours')::float end as ip_bin_num_emails_last_24_hours,
case when (variables ->> 'ip_bin_num_emails_last_36_hours') = 'no_data' then null else (variables ->> 'ip_bin_num_emails_last_36_hours')::float end as ip_bin_num_emails_last_36_hours,
case when (variables ->> 'ip_bin_num_emails_last_72_hours') = 'no_data' then null else (variables ->> 'ip_bin_num_emails_last_72_hours')::float end as ip_bin_num_emails_last_72_hours,
case when (variables ->> 'ip_bin_num_emails_last_7_days') = 'no_data' then null else (variables ->> 'ip_bin_num_emails_last_7_days')::float end as ip_bin_num_emails_last_7_days,
case when (variables ->> 'ip_bin_ratio_emails_last_10_mins_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_emails_last_10_mins_and_baseline')::float end as ip_bin_ratio_emails_last_10_mins_and_baseline,
case when (variables ->> 'ip_bin_ratio_emails_last_30_mins_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_emails_last_30_mins_and_baseline')::float end as ip_bin_ratio_emails_last_30_mins_and_baseline,
case when (variables ->> 'ip_bin_ratio_emails_last_1_hour_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_emails_last_1_hour_and_baseline')::float end as ip_bin_ratio_emails_last_1_hour_and_baseline,
case when (variables ->> 'ip_bin_ratio_emails_last_4_hours_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_emails_last_4_hours_and_baseline')::float end as ip_bin_ratio_emails_last_4_hours_and_baseline,
case when (variables ->> 'ip_bin_ratio_emails_last_12_hours_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_emails_last_12_hours_and_baseline')::float end as ip_bin_ratio_emails_last_12_hours_and_baseline,
case when (variables ->> 'ip_bin_ratio_emails_last_24_hours_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_emails_last_24_hours_and_baseline')::float end as ip_bin_ratio_emails_last_24_hours_and_baseline,
case when (variables ->> 'ip_bin_ratio_emails_last_36_hours_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_emails_last_36_hours_and_baseline')::float end as ip_bin_ratio_emails_last_36_hours_and_baseline,
case when (variables ->> 'ip_bin_ratio_emails_last_72_hours_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_emails_last_72_hours_and_baseline')::float end as ip_bin_ratio_emails_last_72_hours_and_baseline,
case when (variables ->> 'ip_bin_ratio_emails_last_7_days_and_baseline') = 'no_data' then null else (variables ->> 'ip_bin_ratio_emails_last_7_days_and_baseline')::float end as ip_bin_ratio_emails_last_7_days_and_baseline





from
(select sp.*, p.created_at, p.id as p_id, p.status,
sr.decision,
sr.reason,
sr.variables #> '{Analytic}' as variables,
 al.user_label

 from simulator_results sr left join simulator_parameters sp
  join r_payments rp on sp.payment_id = rp.id
 join payments p on rp.simplex_payment_id =  p.id
  left join mv_all_labels al on p.id = al.payment_id
-- left join fraud_warnings fw on p.id = fw.payment_id
--   left join chargebacks cb on p.id = cb.payment_id
 on sp.id = sr.parameter_id
 where  sr.run_id = 4370
--  and sr.parameter_id = 745901
 ) sim_results ) sr
where  ip_bin_ratio_emails_last_12_hours_and_baseline > 15

group by 1 order by 1

;
select distinct status_code, count(*) from simulator_results where run_id = 4130 group by 1;
select distinct status_code, count(*) from simulator_results where run_id = 4265 group by 1;
select lower((response_data #>> '{bank, name}')) from enrich_binlist where (response_data #>> '{bank, name}') is not null order by 1 desc limit 50;

select * from simulator_runs order by id desc limit 300;