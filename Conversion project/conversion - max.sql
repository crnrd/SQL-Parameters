
select
Partner_Type, Partner_Name, month, payment_state,
count(payment_id) AS number_of_payments,
verification_page_status
from

(select
payment_id, Partner_Name, Partner_Type, date AS month,
CASE WHEN payment_id >= 27468 THEN 1 ELSE 0 END AS verification_page_status,
MAX(
CASE

WHEN payment_status > 0 	and 	payment_status  not in (12, 8, 16, 18) 				THEN 	'00 - payment submitted'

-- verification page conversion
WHEN payment_status in (8, 16, 18) and verification_request_null = 0 and is_bender = 1 and verification_status = 0 and verification_type = 0 THEN '10 - photo verification request expired'
WHEN payment_status in (8, 16, 18) and verification_request_null = 0 and is_bender = 1 and verification_status = 0 and verification_type = 1 THEN '11 - video verification request expired'
WHEN payment_status in (8, 16, 18) and verification_request_null = 0 and is_bender = 1 and verification_status = 1 and verification_type = 0 THEN '12 - photo verification in progress'
WHEN payment_status in (8, 16, 18) and verification_request_null = 0 and is_bender = 1 and verification_status = 1 and verification_type = 1 THEN '13 - video verification in progress'

WHEN payment_status = 0 	and 	num_auth_success >= 1 and auth_status = 'success'		THEN 	'30 - credit card velocity or form timed out'

--3DS conversion
-- WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed' and ThreeDS_status = 0 and acquirerresponsemessage = '' THEN '31 - 3DS Y\Y but failed'
-- WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed' and ThreeDS_status = 1 and acquirerresponsemessage = '' THEN '32 - 3DS Y\A but failed'
-- WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed' and ThreeDS_status = 2 and acquirerresponsemessage = '' THEN '33 - 3DS Y\N '
-- WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed' and ThreeDS_status = 3 and acquirerresponsemessage = '' THEN '34 - 3DS N'
WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed' and ThreeDS_status in (0,1,3) and acquirerresponsemessage = '' THEN '32 - 3DS Other'
WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed' and ThreeDS_status = 2 and acquirerresponsemessage = '' THEN '33 - 3DS Y\N'



--

WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed'	 and   acquirerresponsemessage ilike ('%expired%') THEN  '41 - auth request failed - expired card'
WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed'	 and   acquirerresponsemessage ilike ('%format%') THEN  '42 - auth request failed - format error'
WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed'	 and   acquirerresponsemessage ilike ('%exceeds%') THEN  '43 - auth request failed - exceeds amount/frequency'
WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed'	 and   acquirerresponsemessage ilike ('%invalid%') THEN  '44 - auth request failed - invalid card number/issuer/acount etc'
WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed'	 and   acquirerresponsemessage ilike ('%funds%') or acquirerresponsemessage ilike ('%permitted%') THEN  '45 - auth request failed - no funds or bank limit'
WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed'	 and   acquirerresponsemessage ilike ('%issuer%') THEN  '46 - auth request failed - issuer problems'
WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed'	 and   acquirerresponsemessage ilike ('%honor%') THEN  '47 - auth request failed - do not honor'
WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed'	 and   acquirerresponsemessage ilike ('%pickup%') THEN  '48 - auth request failed - fraud'
WHEN auth_id_null = 0			and 	num_auth_success = 0 and auth_status = 'failed'	 THEN  '40 - auth request failed - other'

--

-- WHEN auth_id_null = 0			and 	num_auth_status = 0	  and times_clicked_pay > 0  then '49 - user clicked pay' || to_char(times_clicked_pay, '999') || ' times, didnt get back to form'
WHEN auth_id_null = 0			and 	num_auth_status = 0	 and 	times_clicked_pay > 1		THEN  '50 - clicked pay more than once'
WHEN auth_id_null = 0			and 	num_auth_status = 0	 and 	times_clicked_pay = 1		THEN  '51 - clicked pay once'
WHEN auth_id_null = 0			and 	num_auth_status = 0	 and 	times_clicked_pay = 0		THEN  '52 - auth request unanswered' -- also will be true if exiting 3ds window without cancelling

WHEN validation_request_body_null = 0 AND is_verified = 5 THEN 	'60 - email and phone verified but auth not called'
WHEN validation_request_body_null = 0 AND is_verified = 2 and email_verified = 1 THEN '72 - user verified email but did not click Next again'
WHEN validation_request_body_null = 0 AND is_verified = 2 and email_verified = 0 THEN '73 - user did not complete email verification'
WHEN validation_request_body_null = 0 AND is_verified = 3 and phone_verified = 1 THEN '74 - user verified phone but did not click Next again'
WHEN validation_request_body_null = 0 AND is_verified = 3 and phone_verified = 0 THEN '75 - user did not complete phone verification'
WHEN validation_request_body_null = 0 AND is_verified = 0 and email_verified = 1 and phone_verified = 1 THEN '76 - user verified email and phone but did not click Next again'
WHEN validation_request_body_null = 0 AND is_verified = 0 and email_verified = 1 and phone_verified = 0 THEN '77 - user verified email but did not click Next again'
WHEN validation_request_body_null = 0 AND is_verified = 0 and email_verified = 0 and phone_verified = 1 THEN '78 - user verified phone but did not click Next again'
WHEN validation_request_body_null = 0 AND is_verified = 0 and email_verified = 0 and phone_verified = 0 THEN '79 - user did not complete email and phone verification'
WHEN validation_request_body_null = 0 AND email_verified = 0 and phone_verified = 0 AND form_error > 0 THEN '80 - error in form'
--
WHEN validation_request_body_null = 1                                                   								THEN 	'81 - user did not press next on form'

ELSE 																														'100 - Error - no matching payment state - Error!'
END)
as payment_state
FROM
(SELECT p.id AS payment_id, pt.name AS Partner_Name, pr.raw_response ->> 'acquirerresponsemessage'  acquirerresponsemessage,
pt.service_type AS Partner_Type,
to_char(date_trunc('month',p.created_at),'MM/YYYY') Date, p.status AS payment_status,
case when pr.id is null then 1 else 0 end as auth_id_null, pr.status AS auth_status,
case when p.validation_request_body is null then 1 else 0 end as validation_request_body_null,
case when vr.id is null then 1 else 0 end as verification_request_null,
             ube.is_verified,
             ube.email_verified,
             ube.phone_verified,
             ube.form_error,
             ube.times_clicked_pay,
             ube.times_show_form,
             ds.ThreeDS_status,
             ds.num_auth_status,
             ds.num_auth_success,
             v.is_bender,
             v.verification_status,
             v.verification_type


FROM payments p
  LEFT JOIN partner_end_users pu ON p.partner_end_user_id = pu.id
  LEFT JOIN proc_requests pr
         ON p.id = pr.payment_id
        AND pr.tx_type = 'authorization'
  LEFT JOIN partners pt ON pu.partner_id = pt.id
  LEFT JOIN verification_requests vr ON vr.payment_id = p.id
          LEFT JOIN (SELECT payment_id,
                          MAX(CASE WHEN ((response_data ->> 'emailVerification') = 'true') AND ((response_data ->> 'phoneVerification') = 'true') THEN 0
                          				 WHEN response_data ->> 'emailVerification' = 'true' THEN 2
                          				 WHEN response_data ->> 'phoneVerification' = 'true' THEN 3
-- WHEN response_data ->> 'status' = 'OK' THEN 5
                                   WHEN event_type = 'validate' and ((response_data ->> 'phoneVerification') is null) and ((response_data ->> 'emailVerification') is null) and not ((response_data #>> '{}') ilike '%error%')  THEN 5
                          				 ELSE NULL END) AS is_verified,
                          SUM(CASE WHEN response_data ->> 'verified' = 'true' THEN 1 ELSE 0 END) AS phone_verified,
                          SUM(CASE WHEN response_data ->> 'isVerified' = 'true' THEN 1 ELSE 0 END) AS email_verified,
                          SUM(CASE WHEN (event_type = 'validate') and ((response_data #>> '{}') ilike '%errors%') THEN 1 ELSE 0 END) AS form_error,
                          SUM(CASE WHEN (event_type = 'clicked_pay') THEN 1 ELSE 0 END) as times_clicked_pay,
                          SUM(CASE WHEN (event_type = 'show_form') THEN 1 ELSE 0 END) as times_show_form
                   FROM user_browser_events
                   GROUP BY 1) ube ON ube.payment_id = p.id
  LEFT JOIN (SELECT payment_id,
  MIN(case when pr.raw_response #>> '{enrolled}' = 'Y' and pr.raw_response #>> '{status}' = 'Y' THEN 0
         when ((pr.raw_response #>> '{enrolled}') = 'Y') and ((pr.raw_response #>> '{status}') = 'A') THEN 1
         when pr.raw_response #>> '{enrolled}' = 'Y' and pr.raw_response #>>'{status}' = 'N' THEN 2
         when pr.raw_response #>> '{enrolled}' = 'N' THEN 3
         ELSE 4 END) AS ThreeDS_status,
         SUM (case when pr.status is null then 0 else 1 end) as num_auth_status,
         SUM (case when pr.status = 'success' then 1 else 0 end) as num_auth_success
         FROM proc_requests as pr
         GROUP BY payment_id) as ds ON  ds.payment_id = p.id


LEFT JOIN (SELECT payment_id,
           CASE WHEN requesting_user_id = -1 THEN 1 ELSE 0 END AS is_bender,
           CASE vr.status WHEN 'expired' THEN 0
                          WHEN 'in_progress' THEN 1
                          ELSE NULL END AS verification_status,
           CASE WHEN (allow_verifications #>> '{}') ilike '%photo_selfie%' THEN 0
                WHEN (allow_verifications #>> '{}') ilike '%video_selfie%' THEN 1
                ELSE NULL END AS verification_type
           FROM verification_requests as vr) AS v ON v.payment_id = p.id










-- remoing payments from old processor
 WHERE --p.id>17742
 p.id >= 31682 -- from 'clicked pay' introduction
 --p.id in (select id from payments where created_at >= '2015-11-04')
-- removing test payments
  and pt.name<>'btc4cc'
and p.id not in (SELECT p.id
FROM payments p
WHERE p.status!=12 AND p.id <= 70
OR    p.id IN (SELECT payment_id
               FROM comments
               WHERE LOWER (text_data) LIKE ANY(ARRAY['test%','% test%'])
               UNION
               SELECT p.id AS payment_id
               FROM payments p
                 LEFT JOIN partner_end_users pu ON p.partner_end_user_id = pu.id
               WHERE pu.partner_id = 2 -- example
               OR p.id = 270
               OR    pu.email LIKE 'info@gigatux.com'
               OR    (pu.email LIKE 'erez%' AND p.status != 2)))
order by p.id) a
--
group by 1,2,3,4,5) b  group by 1,2,3,4,6 order by payment_state asc, partner_name, month;




