-- CONSERVATIVE GROUP FOR COMPARISON WITH LIBERAL CHAMPION - UPDATES FROM LIVE TABLES!

INSERT INTO simulator_groups
(
  description
)
VALUES
(
  '$[?description]'
);

WbVarDef group_id=@"SELECT MAX(id) FROM simulator_groups";

WITH p AS
(
  SELECT id,
         created_at,
         handling_at
  FROM payments
  WHERE id IN (SELECT DISTINCT payment_id
               FROM decisions
               WHERE (variables #>> '{Analytic, risk_mode}') = 'liberal'
               AND   created_at >NOW() - INTERVAL '5 days') -- put here the time frame when liberal nibbler ran
               and status not in (0, 12, 19, 20)
) INSERT INTO simulator_parameters
(
  group_id,
  payment_id,
  time_point,
  risk_mode
)
SELECT ($[group_id],payment_id,
       pit,
       'conservative'
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


     commit;
