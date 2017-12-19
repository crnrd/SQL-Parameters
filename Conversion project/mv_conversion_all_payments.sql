CREATE MATERIALIZED VIEW mv_conversion_all_payments AS

SELECT
  form_billing_info.s_payment_id,

  CASE
  WHEN p.status = 2
    THEN '10 approved'
  WHEN cancelled_payments.cancellation_reason IS NOT NULL
    THEN '09 cancelled'
  WHEN post_kyc.payment_status_in_stage IS NOT NULL
    THEN '08 post_kyc'
  WHEN post_auth_verifications.payment_status_in_stage IS NOT NULL
    THEN '07 post_auth_verifications'
  WHEN post_auth.payment_status_in_stage IS NOT NULL
    THEN '06 post_auth'
  WHEN auth.payment_status_in_stage IS NOT NULL
    THEN '05 auth'
  WHEN pre_auth.payment_status_in_stage IS NOT NULL
    THEN '04 pre_auth'
  WHEN payment.payment_status_in_stage IS NOT NULL
    THEN '03 payment'
  WHEN email_and_phone_verifications.payment_status_in_stage IS NOT NULL
    THEN '02 email_and_phone_verifications'
  WHEN form_billing_info.payment_status_in_stage IS NOT NULL
    THEN '01 form_billing_info'
  ELSE 'unexpected value' END AS farthest_stage_for_payment,

  CASE
  WHEN cancelled_payments.cancellation_reason IS NOT NULL
    THEN 'failed'
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
  WHEN payment.payment_status_in_stage IS NOT NULL
    THEN payment.payment_status_in_stage
  WHEN email_and_phone_verifications.payment_status_in_stage IS NOT NULL
    THEN email_and_phone_verifications.payment_status_in_stage
  WHEN form_billing_info.payment_status_in_stage IS NOT NULL
    THEN form_billing_info.payment_status_in_stage

  ELSE 'unexpected_value' END AS status_in_farthest_stage,

  CASE
  WHEN cancelled_payments.cancellation_reason IS NOT NULL
    THEN cancelled_payments.cancellation_reason
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
  WHEN payment.payment_status_in_stage IS NOT NULL
    THEN payment.status_reason_in_stage
  WHEN email_and_phone_verifications.payment_status_in_stage IS NOT NULL
    THEN email_and_phone_verifications.status_reason_in_stage
  WHEN form_billing_info.payment_status_in_stage IS NOT NULL
    THEN form_billing_info.status_reason_in_stage
  ELSE 'unexpected_value' END AS reason_for_farthest_stage

FROM
  payments p
  LEFT JOIN
  mv_conversion_form_billing_info form_billing_info
    on p.id = form_billing_info.s_payment_id
  LEFT JOIN
  mv_conversion_email_and_phone_verifications email_and_phone_verifications
    on p.id = email_and_phone_verifications.s_payment_id
  LEFT JOIN
  mv_conversion_payment payment
    on p.id = payment.s_payment_id
  LEFT JOIN
  mv_conversion_pre_auth pre_auth
    on p.id = pre_auth.s_payment_id
  LEFT JOIN
  mv_conversion_auth auth
    ON p.id = auth.s_payment_id
  LEFT JOIN
  mv_conversion_post_auth post_auth
    ON p.id = post_auth.s_payment_id
  LEFT JOIN
  mv_conversion_post_auth_verifications post_auth_verifications
    ON p.id = post_auth_verifications.s_payment_id
  LEFT JOIN
  mv_conversion_post_kyc post_kyc
    ON p.id = post_kyc.s_payment_id
  LEFT JOIN
  mv_conversion_cancelled_payments cancelled_payments
    on p.id = cancelled_payments.payment_id
       and cancelled_payments.cancellation_reason in ('manual_cancelled', 'scheduler_cancelled_bug batch_cancelled', 'cancelled_due_to_quote', 'other')
  WHERE p.created_at between now()-interval '37 days' and now()-interval '7 days';
