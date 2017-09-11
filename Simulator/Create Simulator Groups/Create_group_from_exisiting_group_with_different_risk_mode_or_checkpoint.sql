-- ALL RELEVANT PAYMENTS WITH NEW PROCESSOR (a lot... - use limit...)
INSERT INTO simulator_groups
(
  description
)
VALUES
(
  '$[?description]'
);

WbVarDef group_id=@"SELECT MAX(id) FROM simulator_groups";

INSERT INTO simulator_parameters
( group_id,
  payment_id,
  time_point,
  risk_mode, 
  checkpoint_name
)
SELECT $[group_id],
       payment_id,  time_point, 'conservative' as risk_mode, 'pending-payment-manual' as checkpoint_name
FROM (SELECT payment_id, time_point from simulator_parameters where group_id = 1195)a ;

COMMIT;


-- checking your group
select   max(id) from simulator_groups;     

