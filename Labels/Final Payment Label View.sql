--Final Decision Label for Research purposes
--Points of emphasis:
-- 1. Chargeback = chargeback or preventive chargeback
-- 2. Good = status 2,13
-- 3. Cancelled = Status 16, Status 11 when weak decline, reason: 'Bad Indicators, Unable to send Verification' or 'Other'
-- 4. Bad = status 11
drop view v_label_final_payment_label;
create view v_label_final_payment_label as 
select id, label from (
 select id, status, chargeback_at,
 case when status = 15 or chargeback_at is not null then 'chargeback'
      when status in (2,13) then 'good'
      when status = 16 or (status = 11 and id in (select payment_id from decisions where application_name = 'Manual'  and decision = 'declined'
                      and variables#>> '{strength}' = 'Weak'
                      and reason != 'Bad Indicators, Unable to send Verification'
                      and reason != 'Other'
                      order by payment_id desc))
              then 'cancelled'
      when status = 11 then 'bad'
 end "label"
 from payments where id in (select id from payments)
 )a
where label <> ''

;


GRANT ALL PRIVILEGES ON v_label_final_payment_label TO analyst, simplexcc, application;
drop materialized view vm_label_final_payment_label;
create materialized view vm_label_final_payment_label as select * from v_label_final_payment_label;
CREATE INDEX vm_label_final_payment_label_id_idx ON vm_label_final_payment_label (id);
CREATE INDEX vm_label_final_payment_label_label_idx ON vm_label_final_payment_label (label);

select * from vm_label_final_payment_label limit 50;
