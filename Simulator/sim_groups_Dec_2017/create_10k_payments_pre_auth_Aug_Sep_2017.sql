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
LIMIT 10000)

SELECT payment_id, pit as time_point, 'conservative'::risk_mode_type as risk_mode, 'payment-pre-auth'::checkpoint_name as checkpoint_name
FROM (SELECT DISTINCT p.id payment_id,
             d.executed_at AS pit
      FROM p
        LEFT JOIN (SELECT DISTINCT r_payment_id,
                          MIN(TO_TIMESTAMP(variables #>> '{Analytic, executed_at}','YYYY-MM-DD HH24:MI:SS.US')) executed_at
                   FROM decisions
                   WHERE application_name IN ('Bender_Pre_Auth_Decide')
                   GROUP BY 1) d ON d.r_payment_id = p.id) a
