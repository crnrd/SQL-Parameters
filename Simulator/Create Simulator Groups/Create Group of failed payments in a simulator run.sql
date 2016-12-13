-- FAILED PAYMENTS OF A CERTAIN RUN_ID

INSERT INTO simulator_parameters
(
  group_id,
  payment_id,
  time_point,
  risk_mode
)
SELECT (SELECT COALESCE(MAX(group_id) +1,1) FROM simulator_parameters),
       p.payment_id,
       p.time_point,
       'conservative'
FROM simulator_parameters p
WHERE p.id IN (SELECT parameter_id
               FROM simulator_results
               WHERE run_id IN (1445)
               AND   status_code = 1);

COMMIT;

SELECT MAX(group_id)
FROM simulator_parameters;