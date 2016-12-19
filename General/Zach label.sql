--Zach's label
--labels payments as 'Bad', 'Good', or 'Cancelled'

select id, label zachs_label from (
select id, status, chargeback_at,
case when status = 15 or chargeback_at is not null then 'Chargeback'--'Bad'
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
)a;