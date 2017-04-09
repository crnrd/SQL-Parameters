--first_decision:
-- run as simplexcc or application
create or replace view v_label_first_decision as
SELECT id payment_id,
       status,
       CASE
         WHEN id IN (SELECT DISTINCT payment_id
                     FROM verification_requests
                     WHERE requesting_user_id != -1
                     AND   verification_format != 'clarification') THEN 'verify'
         WHEN id IN (SELECT DISTINCT payment_id
                     FROM verification_requests
                     WHERE verification_format = 'clarification') THEN 'clarification'
         WHEN status IN (2,13) THEN 'approved'
         WHEN status IN (11) THEN 'declined'
         WHEN status = 16 THEN 'cancelled'
         ELSE 'else'
       END "label"
FROM payments
WHERE processor_id = 2
AND   id > 40000
AND   status IN (2,11,13,15,16)
;

GRANT ALL PRIVILEGES ON v_label_first_decision TO analyst, simplexcc, application, playground_updater;
alter view v_label_first_decision OWNER to application;

-- run as simplexcc
create materialized view vm_label_first_decision_status as select * from v_label_first_decision;
GRANT ALL PRIVILEGES ON vm_label_first_decision_status TO analyst, simplexcc, application, playground_updater;

CREATE INDEX vm_label_first_decision_status_id_idx ON vm_label_first_decision_status (payment_id);
CREATE INDEX vm_label_first_decision_status_status_idx ON vm_label_first_decision_status (status);
CREATE INDEX vm_label_first_decision_status_label_idx ON vm_label_first_decision_status (label);

alter materialized view vm_label_first_decision_status OWNER to playground_updater;


select max(payment_id) from vm_label_first_decision_status;
select created_at, status from payments where id = 391308;


