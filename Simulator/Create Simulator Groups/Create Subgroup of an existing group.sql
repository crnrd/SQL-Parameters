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
  risk_mode
)
SELECT ($[group_id],
        p.payment_id,
        p.time_point,
        'liberal'
FROM simulator_parameters p
WHERE p.id IN (SELECT id
               FROM simulator_parameters
               where group_id = 949);

COMMIT;

SELECT
 MAX(group_id)
FROM simulator_groups;
