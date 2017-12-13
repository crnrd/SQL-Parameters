CREATE MATERIALIZED VIEW mv_conversion_all_payments AS

SELECT
  pre_auth.s_payment_id,

  CASE
  WHEN post_kyc.payment_status_in_stage IS NOT NULL
    THEN '09 post_kyc'
  WHEN post_auth_verifications.payment_status_in_stage IS NOT NULL
    THEN '08 post_auth_verifications'
  WHEN post_auth.payment_status_in_stage IS NOT NULL
    THEN '07 post_auth'
  WHEN auth.payment_status_in_stage IS NOT NULL
    THEN '06 auth'
  WHEN pre_auth.payment_status_in_stage IS NOT NULL
    THEN '05 pre_auth'
  ELSE 'unexpected value' END AS farthest_stage_for_payment,

  CASE
  WHEN post_kyc.payment_status_in_stage IS NOT NULL
    THEN post_kyc.payment_status_in_stage
  WHEN post_auth_verifications.payment_status_in_stage IS NOT NULL
    THEN post_auth_verifications.payment_status_in_stage
  WHEN post_auth.payment_status_in_stage IS NOT NULL
    THEN post_auth.payment_status_in_stage
  WHEN auth.payment_status_in_stage IS NOT NULL
    THEN auth.payment_status_in_stage :: TEXT
  WHEN pre_auth.payment_status_in_stage IS NOT NULL
    THEN pre_auth.payment_status_in_stage
  ELSE 'unexpected value' END AS status_in_farthest_stage,

  CASE
  WHEN post_kyc.payment_status_in_stage IS NOT NULL
    THEN post_kyc.status_reason_in_stage :: TEXT
  WHEN post_auth_verifications.payment_status_in_stage IS NOT NULL
    THEN post_auth_verifications.status_reason_in_stage
  WHEN post_auth.payment_status_in_stage IS NOT NULL
    THEN post_auth.status_reason_in_stage
  WHEN auth.payment_status_in_stage IS NOT NULL
    THEN auth.status_reason_in_stage
  WHEN pre_auth.payment_status_in_stage IS NOT NULL
    THEN pre_auth.status_reason_in_stage
  ELSE 'unexpected value' END AS reason_for_farthest_stage

FROM
  payments p
  LEFT JOIN
  mv_conversion_pre_auth pre_auth
  on p.id = pre_auth.s_payment_id
  LEFT JOIN
  mv_conversion_auth auth
    ON pre_auth.s_payment_id = auth.s_payment_id
  LEFT JOIN
  mv_conversion_post_auth post_auth
    ON auth.s_payment_id = post_auth.s_payment_id
  LEFT JOIN
  mv_conversion_post_auth_verifications post_auth_verifications
    ON post_auth.s_payment_id = post_auth_verifications.s_payment_id
  LEFT JOIN
  mv_conversion_post_kyc post_kyc
    ON post_auth_verifications.s_payment_id = post_kyc.s_payment_id
  WHERE p.created_at between now()-interval '67 days' and now()-interval '7 days'
        and pre_auth.s_payment_id is not null;
