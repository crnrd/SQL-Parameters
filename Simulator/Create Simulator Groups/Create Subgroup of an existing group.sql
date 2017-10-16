 
INSERT INTO simulator_parameters
( group_id,
  payment_id,
  time_point,
  risk_mode
)
SELECT (SELECT MAX(group_id)+1 FROM simulator_parameters where group_id <10000),
        p.payment_id,
        p.time_point,
        'conservative'
FROM simulator_parameters p
WHERE p.id IN (SELECT id
               FROM simulator_parameters
               where group_id = 2028 limit 100);

COMMIT;

SELECT
 MAX(group_id)
FROM simulator_parameters
 where group_id < 10000;
