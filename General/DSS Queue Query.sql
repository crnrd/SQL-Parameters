 
-- distinct reason,
--  count(distinct id) from (
select  a.id, a.status, a.email, a.partner_name, a.auto_decline, 
verification_request_status, 
kyc_verification_status, 
in_queue_since, 
returning_user, 
analytic_decision, 
tags,  d.decision, d.reason from (
WITH last_queue_event as (
              select payments.id,
              (select event_name from dss_queue_events where payment_id = payments.id order by inserted_at desc limit 1) event_name,
              (select inserted_at from dss_queue_events where payment_id = payments.id and event_name = 'enter_queue' order by inserted_at limit 1) in_queue_since
              from payments
              where status = 1
            )
            select p.*, p.email user_email, pa.full_name partner_name,
              (select count(*) from comments c
                where
                  payment_id = p.id
                  and c.text_data like any (values('%AutoDecline via Bender%'),('%Bender 1st pass decided ''declined''%' ), ('%Bender 2nd pass decided ''declined''%'), ('%pass decided ''recommend_decline''%') )
                ) auto_decline,
              (select vr.status from verification_requests vr
                where vr.payment_id = p.id
                and (vr.status = 'in_progress' or vr.status = 'success')
                order by vr.id desc limit 1) verification_request_status,
              (select v.status from verifications v
                where v.simplex_end_user_id = p.simplex_end_user_id
                and v.status = 'in_progress' and v.verification_type = 'kyc_identity'
                order by v.id desc limit 1) kyc_verification_status,
              coalesce(lqe.in_queue_since, p.created_at) in_queue_since,
              exists(select 1 from payments py
                where py.simplex_end_user_id = p.simplex_end_user_id and py.id <> p.id and py.status > 0
              ) returning_user,
              d.variables -> 'Analytic' ->> 'decision' analytic_decision,
              (select array(select name
                from dss_payment_tags dpt
                  join dss_payment_tags_payments dptp on dpt.id = dptp.dss_payment_tag_id
                where dptp.payment_id = p.id
              )) tags
            from payments p
              join partner_end_users pu on p.partner_end_user_id = pu.id
              join partners pa on pu.partner_id = pa.id
              join last_queue_event lqe on p.id = lqe.id
              left join decisions d on p.id = d.payment_id and d.application_name = 'Bender_Auto_Decide'
            where
              p.status = 1 
              
              and (lqe.event_name <> 'start_handling' or lqe.event_name is null)
            order by pa.service_type asc, in_queue_since asc
            ) a 
            left join decisions d on a.id = d.payment_id 
         left join partners pa on a.partner_name = pa.full_name
            where d.application_name = 'Bender_Auto_Decide' 
            and pa.service_type = 'wallet'
            and a.kyc_verification_status is null
            and a.created_at < date '2017-05-25'
--              d.reason != 'Policy require photo selfie with *THIS PAYMENT* credit card with *SAME PERSON* name on card'
--              and d.reason ilike '%pending%'
-- and ((a.verification_request_status in ('success')) or (a.verification_request_status is null))
-- and (d.variables#>> '{Analytic, variables, Analytic, num_all}')::float < 0.9
-- ) b 
-- group by 1 order by 1 
          

;

select 
distinct p.id, p.status,p.created_at, d.reason, pa.service_type, pa.name
 from payments p 
join partner_end_users peu on p.partner_end_user_id=peu.id join 
partners pa on peu.partner_id=pa.id 
left join decisions d on p.id=d.payment_id and application_name = 'Bender_Auto_Decide' join
(select simplex_end_user_id from (
select *, max(id) over (partition by simplex_end_user_id) max_id from verifications where verification_type='kyc_identity')a
where max_id=id and status='approved')kyc on p.simplex_end_user_id=kyc.simplex_end_user_id
where p.status=1 and p.created_at<'2017-05-25' and pa.service_type='wallet'
;   
