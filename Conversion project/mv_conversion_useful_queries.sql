-- conversion summary by payments: for QA

select
  farthest_stage_for_payment,
  status_in_farthest_stage,
  reason_for_farthest_stage,
  count(s_payment_id),
  max(s_payment_id) as example_payment,
  min(s_payment_id) as example_payment_2

 FROM
   mv_conversion_all_payments
  group by 1,2,3
  order by 1,2,3;


-- conversion summary by payments: for business

with partner_type_per_payment as (

SELECT
  mcap.s_payment_id as payment_id,
  ps.service_type as partner_type
FROM
  mv_conversion_all_payments mcap,
  payments p,
  partner_end_users peu,
  partners ps
WHERE
  mcap.s_payment_id = p.id
  and p.partner_end_user_id = peu.id
  AND peu.partner_id = ps.id
),


all_payments_processed_reasons as (

    select
      s_payment_id,
      farthest_stage_for_payment,
      status_in_farthest_stage,
      CASE
        when farthest_stage_for_payment = '10 approved' then 'approved'
        when reason_for_farthest_stage ilike '%non-3ds%' then 'failed_in_non-3ds'
        when reason_for_farthest_stage ilike '%3ds%' then 'failed_in_3ds'
        when reason_for_farthest_stage ilike '%kyc_and_selfie%kyc%' then 'failed_in_kyc'
        when reason_for_farthest_stage ilike '%kyc_and_selfie%selfie%' then 'failed_in_selfie'
        when reason_for_farthest_stage ilike '%kyc%' then 'failed_in_kyc'
        when reason_for_farthest_stage ilike '%selfie%' then 'failed_in_selfie'
        else reason_for_farthest_stage end as reason_for_farthest_stage

    FROM
      mv_conversion_all_payments
  )

select * from (
select
  partner_type,
  farthest_stage_for_payment,
  status_in_farthest_stage,
  reason_for_farthest_stage,
  1.0 * count(s_payment_id) over (partition by farthest_stage_for_payment, status_in_farthest_stage, reason_for_farthest_stage, partner_type) / count (s_payment_id) over (PARTITION BY partner_type) as percentage_of_total_payments

 FROM
    all_payments_processed_reasons,
    partner_type_per_payment
  WHERE
    all_payments_processed_reasons.s_payment_id = partner_type_per_payment.payment_id
    and farthest_stage_for_payment not in ('01 form_billing_info', '02 email_and_phone_verifications', '03 payment', '04 pre_auth', '05 auth')
              ) all_payments_summarized
  WHERE
    percentage_of_total_payments > 0.001
    and (status_in_farthest_stage = 'failed' or (status_in_farthest_stage = 'success' and farthest_stage_for_payment = '10 approved'))
  group by 1,2,3,4,5
  order by 1,2,3,4;




-- conversion summary by users: for business

with partner_type_per_user as (

SELECT
  mcau.partner_end_user_id as p_end_user_id,
  ps.service_type as partner_type
FROM
  mv_conversion_all_users mcau,
  partner_end_users peu,
  partners ps
WHERE
  mcau.partner_end_user_id = peu.id
  AND peu.partner_id = ps.id
),


all_users_processed_reasons as (

    select
      partner_end_user_id,
      farthest_stage_for_payment,
      status_in_farthest_stage,
      CASE
        when farthest_stage_for_payment = '10 approved' then 'approved'
        when reason_for_farthest_stage ilike '%non-3ds%' then 'failed_in_non-3ds'
        when reason_for_farthest_stage ilike '%3ds%' then 'failed_in_3ds'
        when reason_for_farthest_stage ilike '%kyc_and_selfie%kyc%' then 'failed_in_kyc'
        when reason_for_farthest_stage ilike '%kyc_and_selfie%selfie%' then 'failed_in_selfie'
        when reason_for_farthest_stage ilike '%kyc%' then 'failed_in_kyc'
        when reason_for_farthest_stage ilike '%selfie%' then 'failed_in_selfie'
        else reason_for_farthest_stage end as reason_for_farthest_stage

    FROM
      mv_conversion_all_users
  )

select * from (
select
  partner_type,
  farthest_stage_for_payment,
  status_in_farthest_stage,
  reason_for_farthest_stage,
  1.0 * count(partner_end_user_id) over (partition by farthest_stage_for_payment, status_in_farthest_stage, reason_for_farthest_stage, partner_type) / count (partner_end_user_id) over (PARTITION BY partner_type) as percentage_of_total_users

 FROM
    all_users_processed_reasons,
    partner_type_per_user
  WHERE
    all_users_processed_reasons.partner_end_user_id = partner_type_per_user.p_end_user_id
--     and farthest_stage_for_payment not in ('01 form_billing_info', '02 email_and_phone_verifications', '03 payment', '04 pre_auth', '05 auth')
              ) all_users_summarized
  WHERE
    percentage_of_total_users > 0.001
    and (status_in_farthest_stage = 'failed' or (status_in_farthest_stage = 'success' and farthest_stage_for_payment = '10 approved'))
  group by 1,2,3,4,5
  order by 1,2,3,4;
