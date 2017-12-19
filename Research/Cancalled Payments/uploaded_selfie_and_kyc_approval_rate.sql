
WITH p AS (SELECT id
           FROM payments
           WHERE  created_at between (now() - interval '30 days') and  (now() - INTERVAL '1 days')
AND partner_end_user_id in (
             select id from partner_end_users where partner_id in
            (select id from partners where service_type = 'wallet'))),

  ver as (select payment_id, verification_format from verification_requests where
payment_id in (select id from p))


select distinct verification_status, status, count(id) from (
           select id,status,
case when id in (select payment_id from ver where verification_format = 'clarification')
then 'clarified'
when id in (select payment_id from ver) then 'sent selfie'
else 'not verified' end as verification_status
from payments where id in (select id from p))a
group by 1, 2;


select distinct status, count(distinct initial_payment_id) from verifications where
  initial_payment_id in (SELECT id
           FROM payments
           WHERE  created_at between (now() - interval '30 days') and  (now() - INTERVAL '1 days')
AND partner_end_user_id in (
             select id from partner_end_users where partner_id in
            (select id from partners where service_type = 'wallet')))
group by 1;
select * from verifications order by 1 desc limit 50;

select * from verifications_requests where p

