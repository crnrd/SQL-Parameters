-- ALL RELEVANT PAYMENTS WITH NEW PROCESSOR (a lot... - use limit...)


INSERT INTO simulator_parameters
( group_id,
  payment_id,
  time_point,
  risk_mode, 
  checkpoint_name
)
SELECT (SELECT COALESCE(MAX(group_id) +1,1) FROM simulator_parameters),
       payment_id,  time_point, 'conservative' as risk_mode, 'post-auth-offline' as checkpoint_name
FROM (SELECT payment_id, time_point from simulator_parameters where group_id = 1163)a limit 10;

COMMIT;


-- checking your group
select   max(group_id) from simulator_parameters;     

