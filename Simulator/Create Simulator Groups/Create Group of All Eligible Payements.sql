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

WITH p as (SELECT r_payments.id,
                  r_payments.simplex_payemnt_id as psp_id, 
                  created_at,
                  handling_at
            FROM payments 
            join r_payments 
            on payments.id = r_payments.simplex_payment_id
            WHERE status NOT IN (0,12,19,20, 23) 
            order by id desc limit 100)

INSERT INTO simulator_parameters
( group_id,
  payment_id,
  time_point,
  risk_mode
)
SELECT ($[group_id],
       payment_id, pit, 'conservative'
FROM (SELECT DISTINCT p.id payment_id,
             least(p.handling_at, COALESCE(d.executed_at,pr.proc_updated_at,p.created_at +INTERVAL '5 minutes')) AS pit
      FROM p
        LEFT JOIN (SELECT DISTINCT r_payment_id,
                          MIN(TO_TIMESTAMP(variables #>> '{Analytic, executed_at}','YYYY-MM-DD HH24:MI:SS.US')) executed_at
                   FROM decisions
                   WHERE application_name IN ('Bender_Auto_Decide','Bender')
                   GROUP BY 1) d ON d.r_payment_id = p.id
        LEFT JOIN (SELECT DISTINCT payment_id,
                          MIN(updated_at +INTERVAL '1 minute') AS proc_updated_at
                   FROM proc_requests
                   WHERE status = 'success'
                   AND   tx_type = 'authorization'
                   GROUP BY 1) pr ON p.psp_id = pr.payment_id) a;

COMMIT;


-- checking your group
select   max(group_id) from simulator_groups;     
