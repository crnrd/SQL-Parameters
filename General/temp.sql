SELECT *
FROM simulator_runs
ORDER BY id DESC
LIMIT 300;

SELECT *
FROM simulator_runs
ORDER BY id DESC
LIMIT 50;

SELECT *
FROM simulator_results
WHERE run_id = 4370
ORDER BY 1 DESC
LIMIT 50;

SELECT *
FROM chargebacks
ORDER BY 1 DESC
LIMIT 50;

SELECT max((variables #>> '{Analytic, variables, Analytic, total_approved_amount}') :: FLOAT)
FROM decisions;

SELECT DISTINCT
  status,
  count(*)
FROM payments
WHERE created_at > now() - INTERVAL '30 days'
      AND status IN (2, 11, 16)
GROUP BY 1;

SELECT *
FROM user_browser_events
WHERE event_type ILIKE '%threed%'
ORDER BY 1 DESC
LIMIT 50;

SELECT *
FROM proc_requests
WHERE tx_type = 'authorization' AND created_at < now() - INTERVAL ' 4 days'
ORDER BY 1 DESC
LIMIT 50;

SELECT *
FROM decisions
ORDER BY 1 DESC
LIMIT 50;

SELECT *
FROM enrich_maxmind
ORDER BY 1 DESC
LIMIT 50;
SELECT *
FROM fraud_warnings
ORDER BY 1 DESC
LIMIT 50;

SELECT
  --   max(time_point)
  sp.*,
  sr.*
FROM simulator_results sr LEFT JOIN simulator_parameters sp
    ON sp.id = sr.parameter_id
WHERE
  (variables #>> '{Analytic, linking_valid_response}') != 'yes'
  AND sr.run_id = 4441
ORDER BY payment_id ASC
LIMIT 40;
SELECT simplex_payment_id
FROM r_payments
WHERE id IN (1616704);

WITH p AS (SELECT id
           FROM payments
           WHERE status = 16 AND created_at > now() - INTERVAL '30 days'),
    decisions AS (SELECT DISTINCT ON (payment_id)
                    payment_id,
                    created_at,
                    application_name,
                    decision,
                    reason
                  FROM decisions
                  WHERE application_name IN ('EndUser', 'Scheduler')
                        AND decision = 'cancelled'
                        AND created_at > now() - INTERVAL '14 days'
                        AND payment_id IN (SELECT id IN p)
ORDER BY payment_id DESC, created_at DESC
);


SELECT DISTINCT
  application_name,
  reason,
  count(*)
FROM
  (SELECT DISTINCT ON (payment_id)
     payment_id,
     created_at,
     application_name,
     decision,
     reason
   FROM decisions
   WHERE application_name IN ('EndUser', 'Scheduler')
         AND decision = 'cancelled'
         AND created_at > now() - INTERVAL '14 days'
         AND payment_id IN (SELECT id
                            FROM payments
                            WHERE partner_end_user_id IN
                                  (SELECT id
                                   FROM partner_end_users
                                   WHERE partner_id IN (SELECT id
                                                        FROM partners
                                                        WHERE service_type = 'wallet')))

   ORDER BY payment_id DESC, created_at DESC

  ) dec
GROUP BY 1, 2;
-- select distinct payment_id,
-- max(case when decision = 'cancelled' and application_name = 'Scheduler' and reason = 'Verification Timed Out'
--   then 1 else 0 end) as selfie_sched_cancellation,
--   max(case when decision = 'cancelled' and application_name = 'Scheduler' and reason = 'Verification Session Closed'
-- then 1 else 0 end) as kyc_sched_cancellation,
--   max(case when decision = 'cancelled' and application_name = 'EndUser' and reason = 'Refused Verification'
-- then 1 else 0 end) as user_selfie_cancellation
-- from decisions where payment_id in (select id from payments where status = 16)
-- group by 1 order by 1 desc limit 50;
;


SELECT DISTINCT
  reason,
  count(DISTINCT payment_id)
FROM decisions
WHERE application_name = 'Scheduler'
GROUP BY 1
ORDER BY 1 DESC
LIMIT 50;

SELECT *
FROM verification_requests
WHERE payment_id = 1839785;
SELECT *
FROM verifications
WHERE initial_payment_id = 1839785;


select count(distinct payment_id) from comments where text_data = 'Cancelled because of change in BTC rate (broker policy)'
and created_at > now() - interval '30 days';

select sum(total_amount_usd::float) from payments where status = 16 and
                                                        created_at between (now() - interval '60 days') and  (now() - INTERVAL '30 days')
--
-- and id in (select payment_id from comments where
--  text_data = 'Cancelled because of change in BTC rate (broker policy)')
--  and partner_end_user_id in (
--              select id from partner_end_users where partner_id in
--             (select id from partners where service_type = 'wallet'))
;



select * from payments where status = 20 and
  id not in (select payment_id from decisions where application_name = 'Bender_Pre_Auth_Decide')
  and created_at > now() - interval '30 days'
  and partner_end_user_id in (
             select id from partner_end_users where partner_id in
            (select id from partners where service_type = 'wallet'))
order by 1 desc limit 50;


;
select distinct application_name from decisions;
select * from verification_requests where allow_verifications #>> '{0}' = 'kyc_identity'
order by 1 desc limit 50;

-- select distinct p.status, count (distinct verification_requests.payment_id)
select verification_requests.payment_id
from verification_requests
left join payments p on p.id = verification_requests.payment_id
where
  allow_verifications #>> '{0}' in ('photo_selfie', 'video_selfie')
and verification_requests.status = 'success'
-- and verification_format = 'clarification'
and verification_requests.payment_id in (SELECT id
           FROM payments
           WHERE  created_at between (now() - interval '30 days') and  (now() - INTERVAL '1 days')
AND partner_end_user_id in (
             select id from partner_end_users where partner_id in
            (select id from partners where service_type = 'wallet'))
 and id not in (select
                          payment_id from comments where text_data = 'Cancelled because of change in BTC rate (broker policy)')
and id not in (select payment_id  from decisions where application_name = 'Manual' and decision = 'declined')
    and status = 11
)
-- GROUP BY 1
;


select distinct reason, count(distinct payment_id) from decisions where application_name = 'Manual' and decision = 'declined'
and created_at > now() - interval '30 days'
GROUP BY 1;


select distinct original_http_ref_url, count(*) from payments where created_at > now() - interval '60 days'
GROUP BY  1;
select * from partners;

select a.bin_country, count(1)
from (
SELECT
       a.payment_id,
       data -> 'binCountry' bin_country--,
      --- masked_credit_card
     ---  pr.request_data ->> 'amount' amount --- - ,
   /*    pr.request_data #>> '{threeds_attempted}' threeds_attempted,
       CASE
         WHEN status = 'failed' THEN 0
         WHEN status = 'success' THEN 1
         ELSE -1
       END status,
       created_at,
       MAX(created_at) OVER (PARTITION BY masked_credit_card,pr.request_data ->> 'amount' ORDER BY pr.id ROWS BETWEEN 1 following AND 1 following) next_created_at,
       MAX(CASE WHEN status = 'failed' THEN 0 WHEN status = 'success' THEN 1 ELSE -1 END) OVER (PARTITION BY masked_credit_card,pr.request_data ->> 'amount' ORDER BY pr.id ROWS BETWEEN 1 following AND 1 following) next_status*/
FROM (SELECT payment_id
      FROM chargebacks cb
      where cb.status = '1st_chargeback'
      UNION
      SELECT payment_id
      FROM fraud_warnings fw) a,
     proc_requests pr,
     enrich_maxmind em
WHERE pr.payment_id = a.payment_id
AND   pr.created_at > '2017-01-01'

AND   pr.status = 'success'
---and pr.tx_type = 'capture-authorization'
AND   processor = 'ecp'
AND   CAST(em.context -> 'payment_id' AS VARCHAR) = CAST(pr.payment_id AS VARCHAR)
---ORDER BY a.payment_id LIMIT 100;)
)a
group by a.bin_country;

select * from enrich_maxmind order by 1 desc limit 50;

select * from chargebacks where inserted_at > date '01-01-2017' order by 1  limit 50 ;

select * from r_payment_events where created_at >;

select * from payments order by 1 desc limit 5;