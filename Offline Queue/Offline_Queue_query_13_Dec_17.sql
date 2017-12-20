with decided_payments as (
  -- return payments that have automatic decisions and are already approved or declined
  select d.payment_id
  from
    decisions d
    join payments p on d.payment_id = p.id and p.status in (2, 11)
  where
    d.executed_at > $1
    and d.application_name in ('Nibbler_post_kyc', 'Bender_Auto_Decide')
), d_payments as (
  -- filter out payments that already have offline manual decisions
  select d.payment_id
  from
    decisions d
  where
    d.payment_id in (select payment_id from decided_payments)

  except

  select d.payment_id
  from
    decisions d
  where
    d.payment_id in (select payment_id from decided_payments)
    and d.application_name = 'Offline Manual'
), not_in_queue as (
  -- filter out payments that are already in queue
  select payment_id
  from d_payments

  except

  select qe.payment_id
  from
    dss_queue_events qe
  where
    qe.payment_id in (select payment_id from d_payments)
    and qe.event_name = 'enter_offline_queue'
), last_decision as (
  -- collect last automatic decision of filtered payments
  select d.payment_id, d.created_at,
    last_value(d.application_name) over payment application_name,
    last_value(d.variables) over payment variables,
    last_value(d.reason) over payment reason,
    last_value(d.decision) over payment decision
  from decisions d
  where d.payment_id in (select payment_id from not_in_queue)
    and d.application_name in ('Nibbler_post_kyc', 'Bender_Auto_Decide')
  window payment as (partition by d.payment_id order by d.created_at)

  --This section is for eligibility modifications:
), all_payments as (
  -- filter payments based on their last decision

  (
    -- amount should be all eligible
    select payment_id
    from last_decision
    where
      (variables #>> '{Analytic, variables, Analytic, user_risk_status}') = 'manual'
    order by created_at
  )
  UNION ALL

  (
    -- amount should 10% of the remaining after the above was taken into the queue
    select payment_id
    from last_decision
    where
      decision = 'declined'
      and reason in ('decline_linked_suspiciously_not_recently_approved,' ||
                     'decline_linked_strongly_to_another_user_not_mining_and_not_verified_card_by_selfie',
                     'decline_user_with_many_bad_indicators',
                     'decline_not_verified_card_risky_user_above_limit',
                     'decline_num_all',
                     'decline_too_many_phones',
                     'Too many CCs unverified user not enough approvals',
                     'decline_linked_to_bad_indication')
    order by created_at
    limit 70
  )
  union all
  (
    --should be 10% of the queue
    select payment_id
    from last_decision
    where
      decision = 'approved'
      and (
        (variables #>> '{Analytic, eval_rules, manual_verified_card_breached_velocity_limits, reason}') = 'verified card breached velocity limits during last day/week/month'
        or (variables #>> '{Analytic, eval_rules, manual_returning_last_payment_declined, reason}') = 'returning user last payment declined'
        or (variables #>> '{Analytic, variables, Analytic, user_linked_since_last_manually_approved_payment}') = 'true'
        or (variables #>> '{Analytic, eval_rules,decline_linked_strongly_to_another_user_not_mining_and_not_verified_card_by_selfie, reason}')= 'decline_linked_strongly_to_another_user_not_mining_and_not_verified_card_by_selfie'
        or (variables #>> '{Analytic, eval_rules, decline_linked_suspiciously_not_recently_approved, reason}') =
          'decline_linked_suspiciously_not_recently_approved'
        or (variables #>> '{Analytic, eval_rules, decline_linked_since_last_manually_approved_payment, reason}') =
          'linked to another user'
    )
    order by created_at
    limit 70
  )
  union all
  (
    --should be 20% of the queue
    select payment_id
    from last_decision
    where
      decision = 'approved'
      and reason in ('random_approve_num_all_under_limit_low_threshold good approve score',
                     'approve_payment_model_score_low_threshold_under_limit good approve score',
                     'approve_threeds_liable',
                     'decent user nothing bad under limit')
    order by created_at
    limit 140
  )
  UNION ALL
    (
    --should be 20% of the queue if there are enough eligible payments currently never happens
    select payment_id
    from last_decision
    where
      decision = 'declined'
      and reason in ('decline_returning_fraud_decline')
      and (variables #>> '{Analytic, variables, Analytic,card_verified_by_time }') = 'true'
    order by created_at
    limit 30
  )
  UNION ALL
    (
    --should be 20% of the queue if there are enough eligible payments currently never happens.
    select payment_id
    from last_decision
    where
      decision = 'declined'
      and reason not in ('decline_fraud_chargeback_or_preemptive_refund',
                         'decline_other_type_chargeback',
                         'decline_fraud_warning')
      and (variables #>> '{Analytic, variables, Analytic,last_non_auto_decision}') in ('verified,verified_strong,' ||
                                                                                      'strong_approved,' ||
                                                                                      'weak_approved')
    order by created_at
    limit 45
  )
  UNION ALL
    (
    --should be 20% of the queue if there are enough eligible payments currently never happens.
    select payment_id
    from last_decision
    where
       (variables #>> '{Analytic, variables, Analytic,risky_user}') ='true'
    order by created_at
    limit 750
  )
)
select DISTINCT  on (simplex_end_user_id) p.id
from payments p
where
  id in (select payment_id from all_payments limit 350)