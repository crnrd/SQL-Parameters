
INSERT INTO simulator_parameters
( group_id,
  payment_id,
  time_point,
  risk_mode
)
SELECT (SELECT COALESCE(MAX(group_id) +1,1) FROM simulator_parameters),
        p.payment_id,
        p.time_point,
        'conservative'
FROM simulator_parameters p
WHERE p.id IN (SELECT id
               FROM simulator_parameters
               WHERE id BETWEEN (SELECT MIN(id) +5001
                                 FROM simulator_parameters
                                 WHERE group_id = 416) AND (SELECT MAX(id) FROM simulator_parameters WHERE group_id = 416));

COMMIT;

SELECT MAX(group_id)
FROM simulator_parameters;