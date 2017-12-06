WbVarDef rid='$[?rid]';
WbVarDef rvar='$[?rvar]'; -- define as an empty string if not needed. variable in Bender
WbVarDef svar='$[?svar]'; -- define as an empty string if not needed. variable in Simulation

--@WbResult simulator_results
select sp.*, sr.* from simulator_results sr, simulator_parameters sp where 
sr.parameter_id = sp.id and sr.run_id in ($[rid]);

-- @WbResult sim vs real
SELECT sr.run_id,
       d.payment_id,
       d.decision AS real_dec,
       sr.decision sim_dec,
       d.reason real_reason,
       sr.reason sim_reason,
       d.variables#>> '{Analytic, variables, Analytic,  $[rvar]}' AS real_full_var,
       sr.variables#>> '{Analytic,$[svar]}' AS sim_full_var,
       p.status,
       d.variables AS real_var,
       sr.variables sim_var
FROM simulator_results sr
  LEFT JOIN simulator_parameters sp ON sr.parameter_id = sp.id
  LEFT JOIN (SELECT payment_id,
                    decision,
                    reason,
                    variables
             FROM decisions
             WHERE application_name = 'Bender_Auto_Decide'
             AND   analytic_code_version IS NOT NULL) d ON sp.payment_id = d.payment_id
  LEFT JOIN payments p ON p.id = d.payment_id
WHERE sr.run_id IN ($[rid]);


--@WbResult real decisions
select * from decisions where payment_id in (select payment_id from simulator_parameters where id in (select parameter_id from simulator_results where run_id in ($[rid]))); 


-- @WbResult group

select * from simulator_parameters where group_id in (select parameter_group_id from simulator_runs where id in ($[rid]));

-- @WbResult failed runs
select distinct (status_description), count(*)  from (select sp.*, sr.* from simulator_results sr, simulator_parameters sp where 
sr.parameter_id = sp.id and sr.run_id in (4295)) a group by 1;








