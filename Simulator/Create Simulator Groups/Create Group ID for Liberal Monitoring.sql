-- create group
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
       payment_id,
       pit,
       'conservative'
FROM (SELECT DISTINCT p.id payment_id,
             COALESCE(d.executed_at,pr.proc_updated_at,p.created_at +INTERVAL '5 minutes') AS pit
      FROM (
-- ***********************************************************************************************   
-- your query here
-- ***********************************************************************************************     
select distinct d.payment_id as id, p.created_at from decisions d
left join payments p on d.payment_id = p.id
where d.application_name = 'Bender_Auto_Decide' 
and d.analytic_code_version is not null
and d.executed_at > '2016-12-18 21:00:00' -- chnage to relevant time frame 
and d.variables#>>'{Analytic,variables,Analytic,risk_mode}' = 'liberal'  
-- *********************************************************************************************** 
  
-- ***********************************************************************************************    
) p
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

-- check your group
select max(group_id) from simulator_groups;  