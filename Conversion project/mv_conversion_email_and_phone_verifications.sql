CREATE MATERIALIZED VIEW mv_conversion_email_and_phone_verifications AS


with email_and_phone_verifications as (

    select
      payment_id,

      case
        when num_email_verifications_requests > 0 and num_approved_email_verifications = 1 then 'success'
        when num_email_verifications_requests > 0 and num_approved_email_verifications = 0 then 'failed'
        when num_email_verifications_requests = 0 then 'no_verification_needed'
        else 'unexpected value' end as email_verification_status,

      case
        when num_phone_verifications_requests > 0 and num_approved_phone_verifications = 1 then 'success'
        when num_phone_verifications_requests > 0 and num_approved_phone_verifications = 0 then 'failed'
        when num_phone_verifications_requests = 0 then 'no_verification_needed'
        else 'unexpected value' end as phone_verification_status
    FROM
      mv_conversion_user_browser_events

  )

SELECT
  epv.payment_id as s_payment_id,
  case
    when epv.email_verification_status = 'failed' then 'failed'
    when epv.phone_verification_status = 'failed' then 'failed'
    else 'success' end as payment_status_in_stage,

  case
    when epv.email_verification_status = 'success' and  epv.phone_verification_status = 'success' then 'success_both_verifications'
    when epv.email_verification_status = 'success' and  epv.phone_verification_status = 'no_verification_needed' then 'success_email_verification'
    when epv.email_verification_status = 'no_verification_needed' and  epv.phone_verification_status = 'success' then 'success_phone_verification'
    when epv.email_verification_status = 'no_verification_needed' and  epv.phone_verification_status = 'no_verification_needed' then 'success_no_verifications'
    when epv.email_verification_status = 'failed' and  epv.phone_verification_status = 'failed' then 'failed_both_verifications'
    when epv.email_verification_status = 'failed' then 'failed_email_verifications'
    when epv.phone_verification_status = 'failed' then 'failed_phone_verifications'
    else 'unexpected_value' end as status_reason_in_stage


FROM
  email_and_phone_verifications epv,
  mv_conversion_form_billing_info fbi
WHERE
  epv.payment_id = fbi.s_payment_id
  and fbi.payment_status_in_stage = 'success';