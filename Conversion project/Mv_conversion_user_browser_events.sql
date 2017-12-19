CREATE MATERIALIZED VIEW mv_conversion_user_browser_events AS

with p_ids as (
  select
    id
  from
    payments
  WHERE
    created_at between now()-interval '37 days' and now()-interval '7 days')

SELECT
  payment_id,
  sum(CASE WHEN event_type = 'show_form'
    THEN 1 ELSE 0 END) AS num_show_form,
  sum(CASE WHEN event_type = 'validate' AND response_data #>> '{status}' = 'OK'
    THEN 1 ELSE 0 END) AS num_validate_ok,
  sum(CASE WHEN event_type = 'validate' AND response_data::text =  '{"status": "OK"}'
    THEN 1 ELSE 0 END) AS num_validate_ok_only,
  sum(CASE WHEN event_type = 'validate' AND response_data #>> '{status}' = 'OK' and response_data #>> '{emailVerification}' = 'true'
    THEN 1 ELSE 0 END) AS num_email_verifications_requests,
  sum(CASE WHEN event_type = 'validate' AND response_data #>> '{status}' = 'OK' and response_data #>> '{phoneVerification}' = 'true'
    THEN 1 ELSE 0 END) AS num_phone_verifications_requests,
  SUM(CASE WHEN event_type = 'validate' and response_data::text ilike '%errors%'
    THEN 1 ELSE 0 END) AS num_form_errors,
  sum(CASE WHEN event_type = 'verify-phone' and response_data #>> '{verified}' = 'true'
    THEN 1 ELSE 0 END) AS num_approved_phone_verifications,
  sum(CASE WHEN event_type = 'verify-email' and response_data #>> '{isVerified}' = 'true'
    THEN 1 ELSE 0 END) AS num_approved_email_verifications,

  sum(CASE WHEN event_type = 'clicked_pay'
    THEN 1 ELSE 0 END) AS num_clicked_pay,
  sum(CASE WHEN event_type = 'pre_auth'
    THEN 1 ELSE 0 END) AS num_sent_to_auth
FROM
  user_browser_events,
  p_ids
WHERE
  p_ids.id = user_browser_events.payment_id
group by 1
ORDER BY payment_id ASC