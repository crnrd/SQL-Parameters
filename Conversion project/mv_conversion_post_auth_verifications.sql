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
    verification_requests vr,
    mv_conversion_payment_ids p_ids
  WHERE
    p_ids.id = vr.payment_id
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
          first_value(v.status) OVER (PARTITION BY payment_id  ORDER BY id desc) AS status
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
  ELSE 'unexpected_value' END AS kyc_status,

  CASE
  WHEN gvraa.is_selfie_requested = TRUE and ss.selfie_decision in ('approved') THEN 'success'
  WHEN gvraa.is_selfie_requested = TRUE AND ss.selfie_decision IN ('declined') THEN 'declined'
  WHEN gvraa.is_selfie_requested = TRUE and (gvraa.how_many_selfies_required-how_many_selfies_returned)>0 AND ss.selfie_decision::text in ('no selfie decision') THEN 'did not respond'
  WHEN gvraa.is_selfie_requested = TRUE and (gvraa.how_many_selfies_required-how_many_selfies_returned)=0 AND ss.selfie_decision::text in ('no selfie decision') THEN 'selfie was not checked'
  WHEN gvraa.is_selfie_requested = FALSE AND ss.selfie_decision in ('no selfie decision') THEN 'not relevant'
  ELSE 'unexpected_value' END AS selfie_status,

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
  mv_conversion_cancelled_payments cp
  ON
    cp.payment_id = gvraa.payment_id
ORDER BY 1 DESC)


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

  ELSE 'unexpected_value' END AS payment_status_in_stage,

  CASE
  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and kyc_status = 'success' and selfie_status = 'success' then 'kyc_and_selfie:_approved_both'
  when is_selfie_requested = TRUE and is_kyc_identity_requested = FALSE and selfie_status = 'success' then 'selfie:_approved'
  when is_selfie_requested = FALSE and is_kyc_identity_requested = TRUE and kyc_status = 'success' then 'kyc:_approved'

  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and kyc_status in ('declined') then 'kyc_and_selfie:_kyc_declined_by_partner'
  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and kyc_status in ('success') and selfie_status in ('declined') then 'kyc_and_selfie:_selfie_declined'
  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and cancellation_reason is not null then concat('kyc_and_selfie:_', cancellation_reason)
  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and kyc_status in ('success') and selfie_status in ('did not respond') then 'kyc_and_selfie:_not_cancelled_selfie_did_not_respond'
  when is_selfie_requested = TRUE and is_kyc_identity_requested = TRUE and kyc_status in ('did not respond') then 'kyc_and_selfie:_not_cancelled_kyc_did_not_respond'


  when is_selfie_requested = TRUE and is_kyc_identity_requested = FALSE and selfie_status in ('declined') then 'selfie:_selfie_declined'
  when is_selfie_requested = TRUE and is_kyc_identity_requested = FALSE and cancellation_reason is not null then concat('selfie:_', cancellation_reason)
  when is_selfie_requested = TRUE and is_kyc_identity_requested = FALSE and selfie_status in ('did not respond') then 'selfie:_not_cancelled_selfie_did_not_respond'

  when is_selfie_requested = FALSE and is_kyc_identity_requested = TRUE and kyc_status in ('declined') then 'kyc:_kyc_declined_by_partner'
  when is_selfie_requested = FALSE and is_kyc_identity_requested = TRUE and cancellation_reason is not null then concat('kyc:_', cancellation_reason)
  when is_selfie_requested = FALSE and is_kyc_identity_requested = TRUE and kyc_status in ('did not respond') then 'kyc:_not_cancelled_kyc_did_not_respond'

  ELSE 'unexpected_value' END AS status_reason_in_stage
FROM
  verification_statuses;


