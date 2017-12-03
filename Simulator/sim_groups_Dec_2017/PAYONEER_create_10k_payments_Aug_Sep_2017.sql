WITH p as (SELECT id,
                  created_at
            FROM r_payments
            WHERE simplex_payment_id is null
            and created_at> '2017-08-01' and created_at< '2017-09-30' limit 10000)

SELECT payment_id, time_point,
  'conservative'::risk_mode_type as risk_mode,
  'post-auth-offline'::checkpoint_name as checkpoint_name
FROM (SELECT DISTINCT p.id payment_id,
             created_at+INTERVAL '5 minutes'  AS time_point
      FROM p
        ) a