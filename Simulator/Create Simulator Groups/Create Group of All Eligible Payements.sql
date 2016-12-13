-- ALL RELEVANT PAYMENTS WITH NEW PROCESSOR (a lot... - use limit...)
WITH p as (SELECT id,
                  created_at,
                  handling_at
            FROM payments
            WHERE status NOT IN (0,12,19,20)
            AND   id > 156000 )

INSERT INTO simulator_parameters
( group_id,
  payment_id,
  time_point,
  risk_mode
)
SELECT (SELECT COALESCE(MAX(group_id) +1,1) FROM simulator_parameters),
       payment_id, pit, 'conservative'
FROM (SELECT DISTINCT p.id payment_id,
             least(p.handling_at, COALESCE(d.executed_at,pr.proc_updated_at,p.created_at +INTERVAL '5 minutes')) AS pit
      FROM p
        LEFT JOIN (SELECT DISTINCT payment_id,
                          MIN(TO_TIMESTAMP(variables #>> '{Analytic, executed_at}','YYYY-MM-DD HH24:MI:SS.US')) executed_at
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


-- checking your group
select   max(group_id) from simulator_parameters;     