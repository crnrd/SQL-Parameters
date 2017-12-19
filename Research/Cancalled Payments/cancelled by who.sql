
WITH p AS (SELECT id
           FROM payments
           WHERE status = 16 AND created_at between (now() - interval '30 days') and  (now() - INTERVAL '1 days')
AND partner_end_user_id in (
             select id from partner_end_users where partner_id in
            (select id from partners where service_type = 'wallet'))
),
    decisions AS (SELECT DISTINCT ON (payment_id)
                    payment_id,
                    created_at,
                    application_name,
                    decision,
                    reason
                  FROM decisions
                  WHERE application_name IN ('EndUser', 'Scheduler', 'Manual', 'Bender_Manual')
                        AND decision = 'cancelled'
                        AND payment_id IN (SELECT id FROM p)
ORDER BY payment_id DESC, created_at DESC
),
ver as (select distinct on (payment_id) payment_id, inserted_at,
(allow_verifications #>> '{0}') as verification_type_sent, verification_type, status
from verification_requests
WHERE payment_id in (select id from p)
  ORDER BY  payment_id DESC, inserted_at DESC),

  final_state AS (SELECT p.id as payment_id,
      d.application_name,
  d.reason,
  ver.verification_type_sent,
  ver.verification_type

  FROM p
LEFT JOIN  decisions d on p.id = d.payment_id
LEFT JOIN  ver on ver.payment_id = p.id)

--   select payment_id, application_name, reason, verification_type_sent
--   FROM p
-- LEFT JOIN  decisions d on p.id = d.payment_id
-- LEFT JOIN  ver on ver.payment_id = p.id
-- LEFT JOIN final_state on p.id = final_state.payment_id
--
-- where application_name = 'Scheduler' and cancellation_reason not ilike '%'






  select distinct cancellation_reason, count(*) from (
--   select * from (
SELECT payment_id,
  case when application_name = 'EndUser' and verification_type_sent in ('photo_selfie', 'video_selfie') then
    'user_cancelled_selfie'
    when application_name = 'EndUser' and verification_type_sent in ('kyc_identity') then
      'user_cancelled_kyc'
    when application_name = 'Scheduler' and verification_type_sent in  ('photo_selfie', 'video_selfie')
    and payment_id in (select payment_id from user_browser_events where event_type = 'verification_later') then
      'scheduler_cancelled_selfie_after_postpone'
    when application_name = 'Scheduler' and verification_type_sent in  ('photo_selfie', 'video_selfie') then
      'scheduler_cancelled_selfie'
    when application_name = 'Scheduler' and verification_type_sent in ('kyc_identity')
    and payment_id in (select payment_id from user_browser_events where event_type = 'verification_later') then
       'scheduler_cancelled_kyc_after_postpone'
    when application_name = 'Scheduler' and verification_type_sent in ('kyc_identity') then
       'scheduler_cancelled_kyc'
    when payment_id in (select
                          payment_id from comments where text_data = 'Cancelled because of change in BTC rate (broker policy)') then 'cancelled_due_to_quote'

    when application_name = 'Manual'  then
       'manual_cancelled'
    when application_name = 'Scheduler'  then
       'scheduler_cancelled_bug'
    when application_name = 'Bender_Manual'  then
       'batch_cancelled'

  else 'other' end as cancellation_reason
FROM final_state) a
--     where cancellation_reason = 'scheduler_cancelled_kyc'
GROUP BY 1

  ORDER BY 1
    limit 50

;




WITH p AS (SELECT id
           FROM payments
           WHERE  status in (2, 11, 16) and created_at between (now() - interval '30 days') and  (now() - INTERVAL '1 days')
AND partner_end_user_id in (
             select id from partner_end_users where partner_id in
            (select id from partners where service_type = 'wallet'))
and id not in (select
                          payment_id from comments where text_data = 'Cancelled because of change in BTC rate (broker policy)')),

  ver as (select distinct on (payment_id) payment_id, inserted_at,
(allow_verifications #>> '{0}') as verification_type_sent, verification_type, status
from verification_requests
WHERE payment_id in (select id from p)
  ORDER BY  payment_id DESC, inserted_at DESC)

select DISTINCT verification_type, status, count(id) FROM (
           select pa.id, pa.status,
case when verification_type_sent in ('photo_selfie', 'video_selfie')
       and ver.payment_id in (select payment_id from user_browser_events where event_type = 'verification_later') then
      'selfie_send_later'
  when verification_type_sent in ('photo_selfie', 'video_selfie') then
   'selfie'
when verification_type_sent in ('kyc_identity')
       and ver.payment_id in (select payment_id from user_browser_events where event_type = 'verification_later') then
      'kyc_send_later'
when verification_type_sent in ('kyc_identity') then 'kyc'
  else 'other'
end as verification_type

    from payments pa
left join ver on ver.payment_id = pa.id
where pa.id in (select id from p)) A
GROUP BY  1, 2
;



