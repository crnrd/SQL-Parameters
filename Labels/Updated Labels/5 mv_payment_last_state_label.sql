-- drop materialized view mv_payment_last_state_label;
create materialized view mv_payment_last_state_label (payment_id)
 as
with p_ids as (select id, status, created_at from payments where status in (2, 13, 15,  11, 16, 22)
-- and id < 820000 
-- id = 416067
)


-- select payment_label, count(*) from 
select * from
(
select pld.payment_id, 
       rp.id as r_payment_id,
case 
when fr.cb_type = 'Fraud' or fr.refund_type = 'Fraud' or fr.fw_type = 'fraud_report' then 'fraud' -- Should be divided into types when those are available. 
when fr.cb_type = 'Service' then 'service_cb'
when fr.refund_type = 'Service' then 'refund'
when p_ids.status = 2 and p_ids.created_at < now() - interval '45 days' then 'approved_old'
else pld.payment_label end as payment_label 


-- Cancelled manually or by EndUser are currently under 'other', should decide if need to get to this resolution

from mv_payment_last_decision_label pld
left join p_ids  on pld.payment_id = p_ids.id
left join mv_fraud_inputs fr on fr.payment_id = p_ids.id
LEFT JOIN r_payments rp ON rp.simplex_payment_id = p_ids.id
where pld.payment_id in (select id from p_ids))labels 
-- group by 1
-- where payment_label = 'fraud'
;
commit;
select distinct payment_label, count(*) from mv_payment_last_state_label group by 1;
select count(*) from mv_payment_last_state_label;



GRANT SELECT ON mv_payment_last_state_label TO analyst, application; 

ALTER TABLE mv_payment_last_state_label OWNER TO playground_updater;

