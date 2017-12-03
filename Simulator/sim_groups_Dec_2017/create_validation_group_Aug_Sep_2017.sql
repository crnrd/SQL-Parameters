WITH p as (SELECT r_payments.id,
                  r_payments.simplex_payment_id as psp_id,
                  payments.created_at,
                  payments.handling_at
            FROM payments
            join r_payments
            on payments.id = r_payments.simplex_payment_id
            WHERE status NOT IN (0,12,19,20, 23)
            and payments.created_at >= '08-01-2017'
            and payments.created_at <= '09-30-2017'
		        and r_payments.id not in (select payment_id from simulator_parameters where group_id=3060)
LIMIT 21400)

SELECT payment_id, pit as time_point, 'conservative'::risk_mode_type as risk_mode, 'payment-post-auth'::checkpoint_name as checkpoint_name
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
                   GROUP BY 1) pr ON p.psp_id = pr.payment_id) a