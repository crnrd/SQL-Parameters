create materialized view mv_fraud_inputs (payment_id, cb_type, refund_type, fw_type)
as 


with p_ids as (select id, status from payments where status in (2, 13, 15,  11, 16, 22) 

),
cb as (select payment_id,
case when reason_code in (4837, 4870,  83, 75) then 'Fraud'
else 'Service' end as cb_type 
from chargebacks where payment_id in (select id from p_ids)), 

-- rrq as (select payment_id, 
-- case when reason_code in (6341, 6321,33) then 'Fraud' 
-- else 'Service' end as rrq_type
-- from retrieval_requests where payment_id in (select id from p_ids)),
 
ref as (select payment_id,
case when descriptive_reason = 'Preventative Fraud' then 'Fraud'
else 'Service' end as refund_type -- assumes there is only one reason for fraud refunds. 
from refunds where payment_id in (select id from p_ids)), 

fw as (select payment_id, fraud_type_raw as fw_type
from fraud_warnings where payment_id in (select id from p_ids))

select * from (
select p_ids.id as payment_id, 
cb.cb_type, 
ref.refund_type, 
fw.fw_type 
from p_ids 
left join cb on cb.payment_id = p_ids.id
left join ref on ref.payment_id = p_ids.id
left join fw on fw.payment_id = p_ids.id
) fraud_inputs
where cb_type is not null or refund_type is not null
 or fw_type is not null
;
commit;
select *  from mv_fraud_inputs  where refund_type = 'Fraud' order by 1 desc limit 50;


