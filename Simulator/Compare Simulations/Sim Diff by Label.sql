with sim_diff as (

select cp.payment_id, cp.time_point, cp.risk_mode, cp.checkpoint_name, 
cp.decision as first_decision, 
cl.decision as second_decision
-- cp.reason as first_reason, 
-- cl.reason as second_reason, 
-- cp.variables as first_vars, 
-- cl.variables as second_vars
 from 

 (select sp.*, sr.* from simulator_results sr left join simulator_parameters sp
 on sp.id = sr.parameter_id
 where  sr.run_id = 3144) cp
 left join
(select sp.*, sr.* from simulator_results sr left join simulator_parameters sp
 on sp.id = sr.parameter_id
 where  sr.run_id = 3149) cl on cl.payment_id = cp.payment_id 
where 
-- cp.decision = 'approved' and cl.decision = 'manual' 
cl.decision = 'approved' and cp.decision = 'manual'
),
all_labels as (select * from mv_new_all_labels where payment_id in (select payment_id from sim_diff))


select *, 
sum(num_payments) over () as total_p,
100*(num_payments)/sum(num_payments) over () as perc_p
from (
select
 distinct 
 user_label
  
 as label,
 count(payment_id) as num_payments
 from all_labels al
 group by 1) a
;
