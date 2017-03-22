WbVarDef base_rid='$[?base_rid]';  -- run id of the baseline simulation
WbVarDef sim_rid='$[?sim_rid]'; -- run id of the compared simulation
WbVarDef base_var='$[?base_var]'; -- define as an empty string if not needed. variable in baseline simulation
WbVarDef sim_var='$[?sim_var]'; -- define as an empty string if not needed. variable in compared Simulation


-- @WbResult sim vs real
select * from (
SELECT base_sim.run_id as base_rid,
       compared_sim.run_id as sim_rid,
       base_sim.group_id as base_group,
       compared_sim.group_id as sim_group,
       base_sim.time_point as base_pit,
       compared_sim.time_point as sim_pit,       
       base_sim.payment_id as payment_id,
       base_sim.decision AS base_dec,
       compared_sim.decision sim_dec,
       base_sim.reason base_reason,
       compared_sim.reason sim_reason,
       compared_sim.variables#>> '{Analytic, $[base_var]}' AS name_on_card_match_1,
       compared_sim.variables#>> '{Analytic,$[sim_var]}' AS name_on_card_match_cl,
       (compared_sim.variables#>> '{Analytic, first_name}') as first_name,
       (compared_sim.variables#>> '{Analytic, last_name}') as last_name,
       (compared_sim.variables#>> '{Analytic, first_name_card}') as first_name_card,
       (compared_sim.variables#>> '{Analytic, last_name_card}') as last_name_card,
       p.status,
       base_sim.variables as base_full_var,
       compared_sim.variables as sim_full_var,
              base_sim.rules as base_full_rules,
       compared_sim.rules as sim_full_rules
FROM (
select * from simulator_results sr
LEFT JOIN simulator_parameters sp ON sr.parameter_id = sp.id
where run_id = ($[base_rid])) base_sim
left join 
(
select * from simulator_results sr
LEFT JOIN simulator_parameters sp ON sr.parameter_id = sp.id
where run_id = ($[sim_rid])) compared_sim
  on base_sim.payment_id = compared_sim.payment_id
left join payments p on p.id = base_sim.payment_id
) a
where 
-- name_on_card_match_1 != name_on_card_match_cl
 not ((base_reason = 'random_approve_num_all_under_limit_high_threshold good approve score') and 
(sim_reason = 'Checkpoint rules did not produce any decision')) and
not ((base_reason = 'random_approve_num_all_under_limit_low_threshold good approve score') and 
(sim_reason = 'Checkpoint rules did not produce any decision')) and 
not ((sim_reason = 'random_approve_num_all_under_limit_high_threshold good approve score') and 
(base_reason = 'Checkpoint rules did not produce any decision')) and 
not ((sim_reason = 'random_approve_num_all_under_limit_low_threshold good approve score') and 
(base_reason = 'Checkpoint rules did not produce any decision')) 
-- and (compared_sim.variables#>> '{Analytic, variables, Analytic,is_first}') !=  (base_sim.variables#>> '{Analytic, variables, Analytic,is_first}')

;
select * from enrich_maxmind order by id desc limit 50







