CREATE MATERIALIZED VIEW mv_conversion_cancelled_payments AS

with p_ids as (
  select
    p.id
  from
    mv_conversion_payment_ids pi,
    payments p
  WHERE
    p.id = pi.id
    and status = 16)

    SELECT
      DISTINCT on (p_ids.id)
      p_ids.id as payment_id,
      CASE

         when application_name = 'EndUser' and vr.allow_verifications#>>'{0}' in ('photo_selfie', 'video_selfie') then
      'user_cancelled_selfie'
      when application_name = 'EndUser' and vr.allow_verifications#>>'{0}' in ('kyc_identity') then
        'user_cancelled_kyc'
      when application_name = 'Scheduler' and vr.allow_verifications#>>'{0}' in  ('photo_selfie', 'video_selfie') then
        'scheduler_cancelled_selfie'
      when application_name = 'Scheduler' and vr.allow_verifications#>>'{0}' in ('kyc_identity') then
         'scheduler_cancelled_kyc'
      when p_ids.id in (select
                      payment_id from comments where text_data = 'Cancelled because of change in BTC rate (broker policy)') then 'cancelled_due_to_quote'
      when application_name = 'Manual'  then
         'manual_cancelled'
      when application_name = 'Scheduler' and reason = 'cancel_decision.cancelled_by_analyst' then
         'scheduler_cancelled_by_analyst'
      when application_name = 'Scheduler'  then
         'scheduler_cancelled_bug'
      when application_name = 'Bender_Manual'  then
         'batch_cancelled'
  else 'other' end as cancellation_reason

    FROM
      p_ids
      LEFT JOIN
      verification_requests vr
        on p_ids.id = vr.payment_id
      LEFT JOIN
      decisions d
        on p_ids.id = d.payment_id
        and d.application_name in ('EndUser', 'Scheduler', 'Manual', 'Bender_Manual')

    order by p_ids.id desc, vr.inserted_at DESC;
