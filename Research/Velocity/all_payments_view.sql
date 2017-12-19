WITH p AS (SELECT
             id,
             created_at,
             status,
             email,
             split_part(email, '@', 2)                                       AS email_domain,
             bin,
             city,
             state,
             zipcode,
             country,
             total_amount_usd,
             substring((simplex_login ->> 'ip') FROM '[0-9]+.[0-9]+.[0-9]+') AS ip3
           FROM payments
           WHERE created_at >= now() - INTERVAL '21 days'),
    variables AS (SELECT DISTINCT ON (payment_id)
                    payment_id,
                    decision,
                    reason,
                    (variables #> '{Analytic, variables, Analytic}') AS variables
                  FROM decisions
                  WHERE
                    application_name = 'Bender_Auto_Decide'
                    AND payment_id IN (SELECT id
                                       FROM p)
                  ORDER BY payment_id, created_at DESC),
    manual_decisions AS (SELECT DISTINCT ON (payment_id)
                           payment_id,
                           decision,
                           reason
                         FROM decisions
                         WHERE
                           application_name IN ('Offline Manual', 'Manual', 'EndUser')
                           AND payment_id IN (SELECT id
                                              FROM p)
                         ORDER BY payment_id, created_at DESC),

  failed_auths as (select distinct payment_id from proc_requests where tx_type = 'authorization' and
  status = 'failed' and payment_id in (select id from p)),

  mm_data as (SELECT DISTINCT ON (p.id)
                p.id as payment_id,
                em.inserted_at,
                (em.data ->> 'ip_isp') as ip_isp,
                (em.data ->> 'countryCode') as ip_country,
                (em.data ->> 'ip_city') as ip_city,
    (em.data ->> 'ip_postalCode') as ip_postalcode,
    (em.data ->> 'ip_netSpeedCell') as ip_netspeedcell,

    (em.data ->> 'binName') as bin_issuer,
    (em.data ->> 'binCountry') as bin_country,
    (em.data ->> 'prepaid') as prepaid,
    (em.data ->> 'riskScore') as mm_riskscore




              FROM payments p
                 JOIN enrich_maxmind em
                  ON (em.request_data ->> 'i') = (p.simplex_login ->> 'ip')
                  AND (em.request_data ->> 'bin') = p.bin
                  AND (em.request_data ->> 'city') = p.city
            AND (em.request_data ->> 'postal') = p.zipcode
              AND (em.request_data ->> 'custPhone') = p.phone
              AND (em.request_data ->> 'region') = p.state
              AND (em.request_data ->> 'domain') = split_part(email, '@', 2)
    WHERE p.id in (select id from p)
    ORDER BY payment_id, em.inserted_at

  ),
  fraud_warnings as (select payment_id, inserted_at from fraud_warnings where payment_id in (select id from p)),
  chargebacks as (select payment_id, inserted_at from fraud_warnings where payment_id in (select id from p))


    select p.*



           FROM p
    LEFT JOIN variables on variables.payment_id = p.id
    LEFT JOIN manual_decisions md on md.payment_id = p.id
      LEFT JOIN failed_auths fa on fa.payment_id = p.id
      LEFT JOIN mm_data on mm_data.payment_id = p.id
      LEFT JOIN fraud_warnings fw on fw.payment_id = p.id
      LEFT JOIN chargebacks cb on cb.payment_id = p.id


            ORDER BY 1 DESC LIMIT 50;


SELECT *
FROM chargebacks
order by 1 desc limit 50;




