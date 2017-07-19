--@WbResult Status Distribution
select status, description, 
100*payments_baseline/sum(payments_baseline) over () as payments_baseline_perc,
payments_baseline, 
100*payments_current/sum(payments_current) over () as payments_current_perc,
payments_current 
from (
select distinct status, sm.description,
sum(case when status in (0, 19, 20, 23) then 1 else 0 end) as failed_payment, 
sum(case when status in (2, 16, 11, 1, 22) then 1 else 0 end) as successful_payment, 
sum (case when created_at  between DATE '03-31-2017' and DATE '04-01-2017' then 1 else 0 end) as payments_baseline, 
sum(case when created_at  between (date '04-04-2017' + time '09:13') and (now() - interval '1 hours')  then 1 else 0 end) as payments_current,  
 count(id) as num_payments
from payments 
left join status_meaning sm on payments.status = sm.code
group by 1,2) a order by 1;
--@WbResult Conversion
select payment_status,
100*payments_baseline/sum(payments_baseline) over () as payments_baseline_perc,
payments_baseline, 
100*payments_current/sum(payments_current) over () as payments_current_perc,
payments_current 
from (
select   
distinct (case when status in (0, 19, 20, 23) then 'failed_payment' 
when status in (2, 16, 11, 1, 22)  then 'successful_payment' else 'not_knows' end) as payment_status,  
sum (case when created_at  between DATE '03-31-2017' and DATE '04-01-2017' then 1 else 0 end) as payments_baseline, 
sum(case when created_at  between (date '04-04-2017' + time '09:13') and (now() - interval '1 hours') then 1 else 0 end) as payments_current,  
 count(id) as num_payments
from payments 
left join status_meaning sm on payments.status = sm.code
group by 1) a order by 1;
--@WbResult Proc Request status distribution
select distinct processor, status, sum(baseline_perc) baseline_perc, 
sum(proc_requests_baseline) proc_requests_baseline,
sum (current_perc) current_perc, 
sum(proc_requests_current) proc_requests_current
 from (
select   processor, status,
100*proc_requests_baseline/sum(proc_requests_baseline) over (partition by processor) as baseline_perc, 
proc_requests_baseline, 
100*proc_requests_current/sum(proc_requests_current) over (partition by processor) as current_perc,
proc_requests_current
from (
select distinct status, processor, raw_response ->> 'acquirerresponsemessage' as message, 
sum (case when created_at  between DATE '03-31-2017' and DATE '04-01-2017' then 1 else 0 end) as proc_requests_baseline, 
sum(case when created_at  between (date '04-04-2017' + time '09:13') and (now() - interval '1 hours') then 1 else 0 end) as proc_requests_current,  
 count(id) as num_requests
 from proc_requests
 where tx_type = 'authorization' 
group by 1, 2, 3 order by 1,2)a) b group by 1,2 order by 1;
--@WbResult Message distribution:
select distinct message, sum(baseline_perc) baseline_perc, 
sum(proc_requests_baseline) proc_requests_baseline,
sum (current_perc) current_perc, 
sum(proc_requests_current) proc_requests_current
 from (
select message,  
100*proc_requests_baseline/sum(proc_requests_baseline) over () as baseline_perc, 
proc_requests_baseline, 
100*proc_requests_current/sum(proc_requests_current) over () as current_perc,
proc_requests_current
from (
select distinct status, raw_response ->> 'acquirerresponsemessage' as message, 
sum (case when created_at  between DATE '03-31-2017' and DATE '04-01-2017' then 1 else 0 end) as proc_requests_baseline, 
sum(case when created_at  between (date '04-04-2017' + time '09:13') and (now() - interval '1 hours') then 1 else 0 end) as proc_requests_current,  
 count(id) as num_requests
 from proc_requests
 where tx_type = 'authorization' 
group by 1, 2 order by 1,2)a) b group by 1 order by 1;
--@WbResult all partners that are not Bitstamp go through Secure Trading
with bitstamp as (
    select p.processor_id, count(*)
    from payments p
    join partner_end_users pu on p.partner_end_user_id = pu.id
    join partners pa on pu.partner_id = pa.id
    where
    pa.id in (20, 22, 28, 19, 26, 34, 33, 32, 27)
    group by 1
),
others as (
    select p.processor_id, count(*)
    from payments p
    join partner_end_users pu on p.partner_end_user_id = pu.id
    join partners pa on pu.partner_id = pa.id
    where
    pa.id not in (20, 22, 28, 19, 26, 34, 33, 32, 27)
    group by 1
)
select 'bitstamp', b.*
from bitstamp b
union all
select 'others', o.*
from others o
;
--@WbResult Status?
select *,cast((zero/(zero+non_zero)) as float) as prc from (
select 'prev' as t, 
cast(count(case when status not in (0,19, 20) then 1 end) as float) as non_zero, cast(count(case when status in (0,19, 20) then 1 end) as float) as zero from payments where created_at > (now() - INTERVAL '1' DAY) and created_at < (now() - INTERVAL '5' HOUR)
UNION ALL 
select 'after' as t, count(case when status not in (0,19, 20) then 1 end) as non_zero, count(case when status in (0,19, 20) then 1 end) as zero from payments where created_at > (now() - INTERVAL '5' HOUR)) as x;
