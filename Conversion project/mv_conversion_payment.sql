CREATE MATERIALIZED VIEW mv_conversion_payment AS


SELECT
  ube.payment_id as s_payment_id,

  case
    WHEN num_clicked_pay > 0 and num_sent_to_pre_auth>0 then 'success'
    else 'failed' END as payment_status_in_stage,

  case
    WHEN num_clicked_pay > 0 and num_sent_to_pre_auth>0 then 'successfuly_sent_to_pre_auth'
    WHEN num_clicked_pay > 0 and num_sent_to_pre_auth=0 and num_sent_to_pre_auth_errors>0 then 'clicked_pay_not_sent_to_pre_auth_for_errors'
    WHEN num_clicked_pay > 0 and num_sent_to_pre_auth=0 then 'clicked_pay_but_not_sent_to_pre_auth'
    WHEN num_clicked_pay = 0 then 'did_not_click_pay'
    else 'unexpected_value' end as status_reason_in_stage

FROM
    mv_conversion_user_browser_events ube,
    mv_conversion_email_and_phone_verifications epv
WHERE
  epv.s_payment_id = ube.payment_id
  and epv.payment_status_in_stage = 'success';