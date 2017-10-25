WbVarDef r_id = $[?run_id];

--@WbResult dec_dif_count
select * from regression_decision_diff_count where second_run_id = $[r_id];

--@WbResult dec_dif_all
select * from regression_decision_diff_all where second_run_id = $[r_id];

--@WbResult var_dif_count
select * from regression_variable_diff_count where second_run_id= $[r_id];

--@WbResult var_dif_all
select * from regression_variable_diff_all where second_run_id = $[r_id];


--@WbResult failed_payments
select sp.*, sr.* from simulator_results sr left join simulator_parameters sp
 on sp.id = sr.parameter_id
 where sr.status_code = 1 and sr.run_id = $[r_id];


