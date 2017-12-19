CREATE MATERIALIZED VIEW mv_conversion_form_billing_info AS


SELECT
  payment_id as s_payment_id,
  case
    when num_show_form > 0 and num_validate_ok > 0 then 'success' else 'failed' end as payment_status_in_stage,

  case
    when num_show_form = 0 then 'form was not showed'
    when num_validate_ok = 0 and num_form_errors > 0 then 'user had form errors and did not continue'
    when num_validate_ok > 0 and num_form_errors > 0 then 'user had form errors and continued'
    when num_validate_ok > 0 then 'user had continued without errors'
    when num_validate_ok = 0 then 'user did not continue'
    else 'unexpected value' end as status_reason_in_stage


FROM
  mv_conversion_user_browser_events