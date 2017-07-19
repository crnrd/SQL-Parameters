with zach_label as 
--Zach's label
--labels payments as 'Bad', 'Good', or 'Cancelled'

(select id, label zachs_label from (
select id, status, chargeback_at,
case when status = 15 or (chargeback_at is not null and chargeback_reason::varchar  in ('4837', '4870', '6341', '6321', '83', '75', '33'))  then 'Fraud Chargeback'--'Bad'
when chargeback_at is not null then 'Service Chargeback'     
when status in (2,13) then 'Good'
     when status = 16 or (status = 11 and id in (select payment_id from decisions where application_name = 'Manual'  and decision = 'declined' 
                     and variables#>> '{strength}' = 'Weak' 
                     and reason != 'Bad Indicators, Unable to send Verification'
                     and reason != 'Other'
                     order by payment_id desc)) 
             then 'Cancelled'
     when status = 11 then 'Bad'      
end "label"
from payments where id in (select id from payments where id>17000)
)a),

-- simulator_results as (select sp.*, sr.* from simulator_results sr left join simulator_parameters sp
--  on sp.id = sr.parameter_id
--  where  sr.run_id = 2661),
 cutoff_results as (select sp.*, sr.* from simulator_results sr left join simulator_parameters sp
 on sp.id = sr.parameter_id
 where sr.run_id = 2743
 and 
 sp.payment_id in (select sp.payment_id from simulator_results sr left join simulator_parameters sp
 on sp.id = sr.parameter_id
 where  sr.run_id = 2738 and sr.decision = 'manual' and 
 reason not in  ('returning user last payment refund', 'manual user risk status',
 'another pending payment', 'nonfraud chargeback reason', 'kyc missing above limit for specific partner'))
 )
  
select distinct   decision, 
sum(case when zachs_label = 'Bad' then perc else 0 end ) as bad_perc,
sum(case when zachs_label = 'Cancelled' then perc else 0 end) as Cancelled_perc ,
sum(case when zachs_label = 'Fraud Chargeback' then perc else 0 end) as fraud_cb_perc ,
sum(case when zachs_label = 'Service Chargeback' then perc else 0 end) as service_cb_perc ,
sum(case when zachs_label = 'Good' then perc else 0 end) as good_perc ,
sum(num_payments) num_payments

-- 100*sum(num_payments)/(sum(num_payments over ()) as perc
from(
select reason, zachs_label, decision, num_payments, 
-- sum(case when zachs_label = 'Bad' then num_payments else 0 end ) as bad_payments 
100*num_payments/sum(num_payments)
over (partition by decision) as perc from (
select distinct cr.reason, zachs_label, cr.decision,  count(distinct cr.payment_id) as num_payments from
 cutoff_results cr
left join 
zach_label zl on zl.id = cr.payment_id

where 
reason not in ('input data none - decline_carder_mail_for_non_approved_user1', 'input data null - decline_emailage_alert_is_first')
-- (sr.variables#>> '{Analytic,risk_mode}') = 'liberal' 
-- and ((reason ilike 'returning % user over limit 1' 
-- and decision = 'verify') or  (reason ilike 'verified card breached velocity limits during last day/week/month' and decision ='manual'))
and (cr.variables#>> '{Analytic, user_previously_reviewed_by_analyst}') = 'false'
-- and (sr.variables#>> '{Analytic, emailage_bad_reason}') = 'true'


--  and (sr.variables#>> '{Analytic, num_user_phones}')::int > 2
-- and
-- and
-- 
-- and
--  (sr.variables#>> '{Analytic, num_new_ccs_since_last_manually_approved_payment}')::int > 2
--  and
--   (sr.variables#>> '{Analytic, num_names_on_cards}')::int > 1
--  and
 
-- --  (sr.variables#>> '{Analytic, num_user_ccs}')::int > and
-- and  (sr.variables#>> '{Analytic, num_all}') != 'no_data' and
--  (sr.variables#>> '{Analytic, num_all}')::float > 0.75
-- and 
-- (sr.variables#>> '{Analytic, mm_riskscore}') != 'no_data' 
-- and (sr.variables#>> '{Analytic, mm_riskscore}')::float < 0.5
-- and
-- and
--  ( 
-- (sr.variables#>> '{Analytic, id_match_1}') = 'true' or
-- (sr.variables#>> '{Analytic, good_user_three_ds_avs_match}') = 'true' or
-- (sr.variables#>> '{Analytic, verified_phone_match}') = 'true' or
-- (sr.variables#>> '{Analytic, phone_bin_ip_location_match}') = 'true' 
-- 
-- )

-- , 'verify'


-- and decision = 'manual' 
group by 1,2,3
order by 1,2,3,4
)a)  a group by 1 order by 1,2
 
 ;
