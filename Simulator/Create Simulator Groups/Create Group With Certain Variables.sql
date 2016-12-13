-- CERTAIN VALUES FOR CERTAIN VARIABLES. good for comparison with new versions of variables / other variables 
WITH p as (SELECT id,
                   created_at,
                   handling_at
            FROM payments
            WHERE id IN (SELECT DISTINCT payment_id
                         FROM decisions
                         WHERE application_name = 'Bender_Auto_Decide'
                         AND   analytic_code_version IS NOT NULL
                         AND   CAST(variables#>> '{Analytic, variables, Analytic, cookie_num_users}' AS INTEGER) = 1
                         AND   CAST(variables#>> '{Analytic, variables, Analytic, btc_address_num_users}' AS INTEGER) = 1
                         AND   CAST(variables#>> '{Analytic, variables, Analytic, ip_num_users}' AS INTEGER) = 1
                         ORDER BY payment_id DESC LIMIT 100))

INSERT INTO simulator_parameters
( group_id,
  payment_id,
  time_point,
  risk_mode
)
SELECT (SELECT COALESCE(MAX(group_id) +1,1) FROM simulator_parameters),
       payment_id,
       pit,
       'conservative'
FROM (SELECT DISTINCT p.id payment_id,
             least(p.handling_at, COALESCE(d.executed_at,pr.proc_updated_at,p.created_at +INTERVAL '5 minutes')) AS pit
      FROM  p
        LEFT JOIN (SELECT DISTINCT payment_id,
                          MIN(TO_TIMESTAMP(variables#>> '{Analytic, executed_at}','YYYY-MM-DD HH24:MI:SS.US')) executed_at
                   FROM decisions
                   WHERE application_name IN ('Bender_Auto_Decide','Bender')
                   GROUP BY 1) d ON d.payment_id = p.id
        LEFT JOIN (SELECT DISTINCT payment_id,
                          MIN(updated_at +INTERVAL '1 minute') AS proc_updated_at
                   FROM proc_requests
                   WHERE status = 'success'
                   AND   tx_type = 'authorization'
                   GROUP BY 1) pr ON p.id = pr.payment_id) a;
COMMIT;

select   max(group_id) from simulator_parameters;     