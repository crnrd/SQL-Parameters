refresh materialized view ma_view_payment_decisions;
refresh materialized view mv_fraud_inputs;
refresh materialized view mv_user_summary;
refresh materialized view ma_view_payment_first_decision_label;
refresh materialized view ma_view_payment_last_decision_label;
refresh materialized view mv_payment_last_state_label;
refresh materialized view mv_new_user_label;
refresh materialized view mv_new_all_labels;
commit;


CREATE INDEX mv_new_all_labels_payment_id on mv_new_all_labels (payment_id);
create index ma_view_payment_decisions_payment_id on ma_view_payment_decisions (payment_id);
create index ma_view_payment_decisions_cutoff_decision on ma_view_payment_decisions (cutoff_decision);
