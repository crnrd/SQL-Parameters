
with p_ids as (select p.id, p.status, p.total_amount, 
pa.service_type, pa.name as partner_name from 
payments p 
join partner_end_users peu on peu.id = p.partner_end_user_id
join partners pa on pa.id = peu.partner_id 
where (p.created_at between date  '08-01-2017' and date '09-01-2017') and p.status in (2, 11, 16, 13, 15, 22)
-- and service_type = 'mining_pool'
and pa.name = 'bitstamp'
-- and p.id in (select payment_id from mv_payment_decisions where manual_decision is not null)
-- and p.id in (select payment_id from mv_payment_decisions where post_auth_decision = 'approved' or post_kyc_decision = 'approved')
-- and id in (select payment_id from mv_payment_decisions where cutoff_decision in ('approved', 'declined'))
),

dec as (select * from mv_payment_decisions where payment_id in (select id from p_ids)), 



ver_req as (select distinct on (payment_id) payment_id, inserted_at, 
case when requesting_user_id <= 0 then 'Auto' 
else 'Manual' end as ver_requesting_user 
from verification_requests where payment_id in (select id from p_ids)
and allow_verifications #>> '{0}' in ('photo_selfie', 'video_selfie') order by payment_id, inserted_at)
-- (select payment_id, decision, reason, application_name, variables from decisions where  payment_id in (select id from p_ids) and application_name = 'Bender_Auto_Decide')

select 
-- manually_decided, 
-- status, 
-- partner_name,
decision, 
-- reason,
-- risky_user, 
--  label,  
num_payments, 
sum(num_payments) over () as total_payments, 
-- sum(num_payments) over (partition by reason) as total_payments_per_reason, 
100*num_payments / sum(num_payments) over () as perc_payments_per_reason, 
total_amount, 
sum(total_amount) over () as total_amounts, 

100*total_amount / sum(total_amount) over () as perc_total_amount



from (
select 
distinct 
-- manually_decided, 
-- status, 
decision, 
-- partner_name,
-- reason,  
-- risky_user, 
-- label,
 count(payment_id) as num_payments, 
 sum(total_amount) as total_amount

    

 from (
 
select p_ids.id as payment_id,
p_ids.status as status, 
total_amount, 
dec.post_auth_reason as reason,  
dec.post_auth_decision as decision,  
p_ids.partner_name,
case when p_ids.id in (select payment_id from mv_payment_decisions where manual_decision is not null) then 1
else 0 end as manually_decided,
(variables ->> 'risky_user') as risky_user, 
-- dec.post_auth_decision as a_dec,
-- dec.post_auth_reason as a_reason, 
-- case when (al.user_label in ('not_approved_user_cancelled_last_payment')) or (al.user_label = 'other' and al.last_state ilike ('%cancelled%')) then ct.cancellation_type
-- when al.user_label = 'other' then al.last_state
-- else al.user_master_label end as label,
al.last_state as label


-- distinct reason, count(distinct payment_id) as num_payments
 from p_ids 
 join  dec on dec.payment_id = p_ids.id
left join  mv_all_labels al on al.payment_id = p_ids.id
left join mv_cancellation_type ct on p_ids.id = ct.payment_id
left join ver_req on ver_req.payment_id = p_ids.id
left join (select payment_id, variables #> '{Analytic, variables, Analytic}' as variables, 
                              variables #> '{Analytic, rules}' as rules
                              from decisions where application_name = 'Bender_Auto_Decide') var on var.payment_id = p_ids.id

where 
dec.post_auth_reason = 'Policy require photo selfie with *THIS PAYMENT* credit card with *SAME PERSON* name on card'
-- dec.post_auth_decision in ('manual','verify')
)a  
--  where risky_user = 'true'
--  where
-- manually_decided = 1 
-- and status = 16
group by 1
-- , 2
-- , 3
) b

-- where label != 'other'

-- and label in ('bad','good')
order by 1 desc
;
