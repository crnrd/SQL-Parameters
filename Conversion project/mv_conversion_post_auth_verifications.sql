CREATE MATERIALIZED VIEW mv_conversion_post_auth_verifications AS

with verification_requests_and_answers AS
(
  SELECT
    vr.inserted_at,
    vr.payment_id,
    case
      when allow_verifications::text ilike '%kyc_identity%' then TRUE
      else false end as is_kyc_identity_requested,
    case
      when allow_verifications::text ilike '%photo_selfie%' then TRUE
      else false end as is_photo_selfie_requested,
    case
      when allow_verifications::text ilike '%video_selfie%' then TRUE
      else false end as is_video_selfie_requested,
    case
      when allow_verifications#>>'{0}' = 'kyc_identity' and vr.status = 'success' then true
      else false end is_kyc_identity_returned,
    case
      when allow_verifications#>>'{0}' = 'photo_selfie' and vr.status = 'success' then true
      else false end is_photo_selfie_returned,
    case
      when allow_verifications#>>'{0}' = 'video_selfie' and vr.status = 'success' then true
      else false end is_video_selfie_returned,
    CASE
      when verification_format = 'clarification' then TRUE
      else false end as is_clarification_requested
  FROM
    verification_requests vr
),

  grouped_verification_requests_and_answers as
(
  select
    payment_id,
    bool_or (is_kyc_identity_requested) as is_kyc_identity_requested,
    bool_or (is_photo_selfie_requested or is_video_selfie_requested) as is_selfie_requested,
    bool_or (is_kyc_identity_returned) as is_kyc_identity_returned,
    bool_or (is_photo_selfie_returned or is_video_selfie_returned) as is_selfie_returned,
    sum (case when is_photo_selfie_requested then 1
         when is_video_selfie_requested then 1
         else 0 end) as how_many_selfies_required,
    sum (case when is_photo_selfie_returned then 1
         when is_video_selfie_returned then 1
         else 0 end) as how_many_selfies_returned,
    sum (case when is_clarification_requested then 1 else 0 end) as how_many_clarifications_requested,
    max (case when is_video_selfie_requested = TRUE then '03 video'
              when is_photo_selfie_requested = TRUE then '02 photo'
              else '01 not a selfie' END) as selfie_type
  FROM
    verification_requests_and_answers
  GROUP BY 1
),

  kyc_identity_status as
  (
    SELECT
      *
    FROM
      (
        SELECT
          gvraa.payment_id,
          last_value(v.status) OVER (PARTITION BY payment_id ORDER BY payment_id DESC) AS status
        FROM
          grouped_verification_requests_and_answers gvraa,
          verifications v
        WHERE
          gvraa.is_kyc_identity_requested = TRUE
          AND gvraa.payment_id = v.initial_payment_id
          AND v.verification_type = 'kyc_identity'
      ) kyc_identity_status_before_grouping
    GROUP BY 1,2
  ),


  selfie_status as
  (
    select
      gvraa.payment_id,
      gvraa.selfie_type,
      CASE
        when d.decision ISNULL then 'no selfie decision'
        else d.decision::text end as selfie_decision
    FROM

      grouped_verification_requests_and_answers gvraa
      left JOIN
      decisions d
      ON
        d.payment_id = gvraa.payment_id
        and d.application_name in ('Manual')
  ),


  cancelled_payments as
  (
    SELECT
      DISTINCT on (d.payment_id)
      d.payment_id,
      CASE
         when application_name = 'EndUser' and vr.allow_verifications#>>'{0}' in ('photo_selfie', 'video_selfie') then
      'user_cancelled_selfie'
      when application_name = 'EndUser' and vr.allow_verifications#>>'{0}' in ('kyc_identity') then
        'user_cancelled_kyc'
      when application_name = 'Scheduler' and vr.allow_verifications#>>'{0}' in  ('photo_selfie', 'video_selfie') then
        'scheduler_cancelled_selfie'
      when application_name = 'Scheduler' and vr.allow_verifications#>>'{0}' in ('kyc_identity') then
         'scheduler_cancelled_kyc'
      when d.payment_id in (select
                            payment_id from comments where text_data = 'Cancelled because of change in BTC rate (broker policy)') then 'cancelled_due_to_quote'

      when application_name = 'Manual'  then
         'manual_cancelled'
      when application_name = 'Scheduler'  then
         'scheduler_cancelled_bug'
      when application_name = 'Bender_Manual'  then
         'batch_cancelled'

  else 'other' end as cancellation_reason

    FROM
      decisions d,
      verification_requests vr
      where
        d.application_name in ('EndUser', 'Scheduler', 'Manual', 'Bender_Manual')
        AND d.decision = 'cancelled'
        and vr.payment_id = d.payment_id
    order by d.payment_id desc, vr.inserted_at DESC
  ),


verification_statuses as
  (
    SELECT
  gvraa.payment_id,
  gvraa.is_kyc_identity_requested,
  gvraa.is_selfie_requested,
  gvraa.how_many_clarifications_requested,
  gvraa.selfie_type,

  CASE
  WHEN gvraa.is_kyc_identity_requested = TRUE and kis.status in ('approved') THEN 'success'
  WHEN gvraa.is_kyc_identity_requested = TRUE AND kis.status IN ('declined') THEN 'declined'
  WHEN gvraa.is_kyc_identity_requested = TRUE AND kis.status IN ('expired', 'in_progress') THEN 'did not respond'
  WHEN gvraa.is_kyc_identity_requested = TRUE and gvraa.is_kyc_identity_returned = FALSE AND kis.status ISNULL THEN 'did not respond'
  WHEN gvraa.is_kyc_identity_requested = FALSE AND kis.status ISNULL THEN 'not relevant'
  ELSE 'unexpected value' END AS kyc_status,

  CASE
  WHEN gvraa.is_selfie_requested = TRUE and ss.selfie_decision in ('approved') THEN 'success'
  WHEN gvraa.is_selfie_requested = TRUE AND ss.selfie_decision IN ('declined') THEN 'declined'
  WHEN gvraa.is_selfie_requested = TRUE and (gvraa.how_many_selfies_required-how_many_selfies_returned)>0 AND ss.selfie_decision::text in ('no selfie decision') THEN 'did not respond'
  WHEN gvraa.is_selfie_requested = TRUE and (gvraa.how_many_selfies_required-how_many_selfies_returned)=0 AND ss.selfie_decision::text in ('no selfie decision') THEN 'selfie was not checked'
  WHEN gvraa.is_selfie_requested = FALSE AND ss.selfie_decision in ('no selfie decision') THEN 'not relevant'
  ELSE 'unexpected value' END AS selfie_status,

  cp.cancellation_reason

FROM
  grouped_verification_requests_and_answers gvraa
  left join
  kyc_identity_status kis
  ON
    kis.payment_id = gvraa.payment_id
  LEFT JOIN
  selfie_status ss
  ON
    ss.payment_id = gvraa.payment_id
  LEFT JOIN
  cancelled_payments cp
  ON
    cp.payment_id = gvraa.payment_id
ORDER BY 1 DESC

  )


SELECT
  payment_id AS s_payment_id,
  selfie_type,
  how_many_clarifications_requested,
  CASE
  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and kyc_status = 'success' and selfie_status = 'success' then 'success'
  when is_selfie_requested = TRUE and is_kyc_identity_requested = FALSE and selfie_status = 'success' then 'success'
  when is_selfie_requested = FALSE and is_kyc_identity_requested = TRUE and kyc_status = 'success' then 'success'

  when kyc_status in ('declined', 'did not respond') then 'failed'
  when selfie_status in ('declined', 'did not respond', 'selfie was not checked') then 'failed'
  when cancellation_reason is not null then 'failed'

  ELSE 'unexpected value' END AS payment_status_in_stage,

  CASE
  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and kyc_status = 'success' and selfie_status = 'success' then 'kyc + selfie: approved both'
  when is_selfie_requested = TRUE and is_kyc_identity_requested = FALSE and selfie_status = 'success' then 'selfie: approved'
  when is_selfie_requested = FALSE and is_kyc_identity_requested = TRUE and kyc_status = 'success' then 'kyc: approved'

  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and kyc_status in ('declined') then 'kyc + selfie: kyc declined by partner'
  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and kyc_status in ('success') and selfie_status in ('declined') then 'kyc + selfie: selfie declined'
  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and cancellation_reason is not null then concat('kyc + selfie: ', cancellation_reason)
  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and kyc_status in ('success') and selfie_status in ('did not respond') then 'kyc + selfie: not cancelled, selfie did not respond'
  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and kyc_status in ('did not respond') then 'kyc + selfie: not cancelled, kyc did not respond'


  when is_selfie_requested = TRUE and is_kyc_identity_requested = FALSE and selfie_status in ('declined') then 'selfie: selfie declined'
  when is_selfie_requested = TRUE and is_kyc_identity_requested = FALSE and cancellation_reason is not null then concat('selfie: ', cancellation_reason)
  when is_selfie_requested = TRUE and is_kyc_identity_requested = FALSE and selfie_status in ('did not respond') then 'selfie: not cancelled, selfie did not respond'

  when is_selfie_requested = FALSE and is_kyc_identity_requested = TRUE and kyc_status in ('declined') then 'kyc: kyc declined by partner'
  when is_selfie_requested = FALSE and is_kyc_identity_requested = TRUE and cancellation_reason is not null then concat('kyc: ', cancellation_reason)
  when is_selfie_requested = FALSE and is_kyc_identity_requested = TRUE and kyc_status in ('did not respond') then 'kyc: not cancelled, kyc did not respond'

  ELSE 'unexpected value' END AS status_reason_in_stage
FROM
  verification_statuses;


