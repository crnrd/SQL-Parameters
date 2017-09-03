refresh materialized view mv_payment_decisions;
refresh materialized view mv_fraud_inputs;
refresh materialized view mv_user_summary;
refresh materialized view mv_payment_first_decision_label;
refresh materialized view mv_payment_last_decision_label;
refresh materialized view mv_payment_last_state_label;
refresh materialized view mv_user_label;
refresh materialized view mv_all_labels;
commit;


GRANT SELECT ON mv_fraud_inputs TO analyst, application;
ALTER TABLE mv_fraud_inputs OWNER TO playground_updater;
GRANT SELECT ON mv_payment_decisions TO analyst, application;
GRANT SELECT ON mv_user_summary TO analyst, application;
GRANT SELECT ON mv_payment_first_decision_label TO analyst, application;
GRANT SELECT ON mv_payment_last_decision_label TO analyst, application;
GRANT SELECT ON mv_payment_last_state_label TO analyst, application;
GRANT SELECT ON mv_user_label TO analyst, application;
GRANT SELECT ON mv_all_labels TO analyst, application;


CREATE INDEX mv_new_all_labels_payment_id on mv_new_all_labels (payment_id);
create index ma_view_payment_decisions_payment_id on ma_view_payment_decisions (payment_id);
create index ma_view_payment_decisions_cutoff_decision on ma_view_payment_decisions (cutoff_decision);
