with velocity_counters as 
(select p.id as payment_id, p.created_at, credit_card, email, 

case when bin_num_payments_baseline = 'no_data' then null else bin_num_payments_baseline::float end as bin_num_payments_baseline

FROM r_payments rp, payments p, velocity_full_sim_max v
WHERE rp.id = v.payment_id AND rp.simplex_payment_id = p.id),

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


select distinct user_master_label, 
count(*) as total_payments,
percentile_cont(0.50) WITHIN group (order by bin_num_payments_baseline) as avgbin_num_payments_baseline


 from velocity_counters vc
 join  labels l on vc.payment_id = l.payment_id  group by 1 order by 1;
