

with 
p_ids  as (select id, email from payments where status in (2, 13, 15,  11, 16, 22)
and  id < 810000 
-- and id = 809944
order by 1 desc limit 50000
), 

select email,

case when fraud_payments > 0 then 'fraudalent_user'
when user_risk_status = 'decline' then 



user_summary us 
where us.email in (select email from p_ids)

;


