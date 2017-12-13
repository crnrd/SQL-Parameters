CREATE MATERIALIZED VIEW mv_conversion_auth AS


WITH conversion_auth_last_decision_for_payment AS
(SELECT
   payment_id,
   max(id) AS last_process
 FROM
   proc_requests
 WHERE
   tx_type = 'authorization'
 GROUP BY 1),


    conversion_auth_processor_status_and_reason AS
  (SELECT
     id,
     payment_id,
     count(id)
     OVER (
       PARTITION BY payment_id ) AS num_auth_attempts,
     processor,
     status,
     CASE
     WHEN processor = 'ecp' AND raw_response #>> '{transaction_type}' = 'authorize' THEN 'non-3ds'
     WHEN processor = 'ecp' AND raw_response #>> '{transaction_type}' = 'authorize3d' THEN '3ds'
     WHEN processor = 'credorax' AND (request_data #>> '{threeds_attempted}') :: BOOLEAN = FALSE THEN 'non-3ds'
     WHEN processor = 'credorax' AND (request_data #>> '{threeds_attempted}') :: BOOLEAN = TRUE THEN '3ds'
     -- Errors:
     WHEN status ISNULL THEN 'Processing error'
     WHEN processor = 'ecp' AND (raw_response #>> '{transaction_type}') :: TEXT ISNULL THEN 'Processing error'
     WHEN processor = 'credorax' AND (request_data #>> '{threeds_attempted}') :: TEXT ISNULL THEN 'Processing error'
     WHEN processor = 'ecp' THEN concat('Unexpected Value: ', raw_response #>> '{transaction_type}')
     WHEN processor = 'credorax' THEN concat('Unexpected Value: ', request_data #>> '{threeds_attempted}')
     ELSE 'Unexpected Value' END AS transaction_type,

     CASE
     WHEN processor = 'credorax' AND request_data #>> '{enrolled_result}' = 'Y' THEN '3ds-enrolled'
     WHEN processor = 'credorax' AND request_data #>> '{enrolled_result}' = 'N' THEN 'not-3ds-enrolled'
     WHEN processor = 'credorax' AND request_data #>> '{enrolled_result}' = 'Error' THEN 'processor returned error'
     WHEN processor = 'credorax' AND (request_data #>> '{threeds_attempted}') :: BOOLEAN = FALSE AND (request_data #>> '{enrolled_result}') :: TEXT IS NULL THEN '3ds not attempted'
     -- Errors:
     WHEN status ISNULL THEN 'Processing error'
     WHEN processor = 'credorax' AND (request_data #>> '{enrolled_result}') :: TEXT IS NULL THEN 'Processing error'
     WHEN processor = 'credorax' THEN concat('Unexpected Value: ', request_data #>> '{enrolled_result}')
     -- defaults:
     WHEN processor = 'ecp' THEN 'processor does not supply information'
     ELSE 'Unexpected Value' END AS is_3ds_enrolled,

     CASE
     WHEN processor = 'ecp' AND status = 'success' THEN 'success'
     WHEN processor = 'ecp' AND status = 'failed' THEN raw_response#>>'{technical_message}'
     WHEN processor = 'credorax' AND status = 'success' THEN 'success'
     WHEN processor = 'credorax' AND status = 'failed' THEN raw_response #>> '{z3}'
     -- Errors:
     WHEN status ISNULL THEN 'Processing error'
     ELSE 'Unexpected Value' END AS reason
   FROM
     proc_requests
   WHERE
     processor IN ('ecp', 'credorax')
     AND tx_type = 'authorization'
  ),

  grouped_reasons as
  (
    SELECT
      id,
      case
        when reason ilike '%cardholder 3D Authentication failure%' then 'cardholder 3D Authentication failure'
        when reason ilike '%CVV2 Failure%' then 'cvv2 failure'
        when reason ilike '%do not honour%' then 'do not honour'
        when reason ilike '%Not permitted on card%' then 'not permitted on card'
        when reason ilike '%sufficient funds%' then 'no sufficient funds'
        when reason ilike '%declined by risk management%' then 'declined by risk management'
        else 'other' end as reason
    FROM
      conversion_auth_processor_status_and_reason
  )

SELECT
  ldfp.payment_id as s_payment_id,
  psar.processor              AS processor_in_stage,
  psar.num_auth_attempts,
  CASE
  WHEN psar.status IS NULL
    THEN 'failed'
  ELSE psar.status::text END        AS payment_status_in_stage,
  CASE
  -- credorax exemption: 3ds when not enrolled in 3ds:
  WHEN psar.status = 'success' AND psar.transaction_type = '3ds' AND psar.is_3ds_enrolled IN ('not-3ds-enrolled') THEN 'success in 3ds when not enrolled in 3ds'
  WHEN psar.status = 'failed' AND psar.transaction_type = '3ds' AND psar.is_3ds_enrolled IN ('not-3ds-enrolled') THEN 'failed in 3ds when not enrolled in 3ds'
  -- success:
  WHEN psar.status = 'success' AND psar.transaction_type = '3ds' AND psar.is_3ds_enrolled IN ('processor does not supply information', '3ds-enrolled') THEN 'success in 3ds'
  WHEN psar.status = 'success' AND psar.transaction_type = 'non-3ds' THEN 'success in non-3ds'
  --failed:
  WHEN psar.status = 'failed' AND psar.transaction_type = '3ds' THEN concat('3ds: ', gr.reason)
  WHEN psar.status = 'failed' AND psar.transaction_type = 'non-3ds' THEN concat('non-3ds: ', gr.reason)
  -- errors:
  WHEN psar.status IS NULL THEN 'Error in process'
  ELSE 'unexpected value' END AS status_reason_in_stage
FROM
  conversion_auth_last_decision_for_payment ldfp,
  conversion_auth_processor_status_and_reason psar,
  grouped_reasons gr
WHERE
  ldfp.payment_id = psar.payment_id
  AND ldfp.last_process = psar.id
  and ldfp.last_process = gr.id;