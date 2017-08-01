-- FAILED PAYMENTS OF A CERTAIN RUN_ID
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
(
  group_id,
  payment_id,
  time_point,
  risk_mode
)
SELECT ($[group_id],
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
FROM simulator_groups;