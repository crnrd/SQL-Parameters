-- run as simplexcc or application
create or replace view v_label_user as
SELECT simplex_end_user_id,
       new_labeling,
       last_decision_id,
       first_decision_id,
       p_id,
       p_status,
       max_approve_id,
       max_decline_cancel_id,
       tx_per_user,
       decline_sum,
       cancel_sum,
       decline_count,
       cancel_count,
       application_name,
       ruling_id,
       decision,
       reason,
              user_risk_status,
       strength,
       handling_at,
       chargeback_at,
       chargeback_reason,
       good_marker1,
       bad_marker1,
       cb_f_marker,
       cb_marker,
       cb_f_user,
       cb_user,
       good_user,
       bad_user,
       weak_approve
FROM (SELECT *,
             CASE
               WHEN (cb_f_user = '1') OR (bad_user = '1') THEN 'Bad'
               WHEN cb_user = '1' THEN 'Undefined_cb_user'
               WHEN good_user = '1' THEN 'Good'
               WHEN cancel_sum = tx_per_user THEN 'Unknown'
               WHEN weak_approve = '1' THEN 'Weak Good'
               ELSE 'no_data'
             END new_labeling
      FROM (SELECT *,
                   MAX(cb_f_marker) OVER (PARTITION BY simplex_end_user_id) cb_f_user,
                   MAX(cb_marker) OVER (PARTITION BY simplex_end_user_id) cb_user,
                   --marks all payment made by the user as chargeback-user
                   MAX(good_marker1) OVER (PARTITION BY simplex_end_user_id) AS good_user,
                   --marks all payment made by the user as good-user
                   MAX(bad_marker1) OVER (PARTITION BY simplex_end_user_id) AS bad_user
            FROM
            --marks all payment made by the user as good-user
            (SELECT *,
                    CASE
                      WHEN ((decline_sum > 0 OR cancel_sum > 0) AND last_decision_id = p_id AND p_status = 2) OR (decline_sum = 0 AND cancel_sum = 0 AND tx_per_user > 1) OR (tx_per_user = 1 AND p_status = 2 AND EXTRACT(DAY FROM NOW() - handling_at) > 100) OR ((decline_sum > 0 OR cancel_sum > 0) AND p_status = 2 AND application_name = 'Manual' AND p_id > max_decline_cancel_id) OR (decline_sum = 0 AND cancel_sum > 0 AND p_id = max_approve_id AND EXTRACT(DAY FROM NOW() - handling_at) > 100) OR (tx_per_user = 1 AND p_status = 2 AND strength = 'Strong')
             --user with 1 payment who had strong approve
             THEN '1'
                    END good_marker1,
                    --marks individual payments as good indicator for the user
                    CASE
                      WHEN (last_decision_id = p_id AND decline_count = 1 AND tx_per_user > 1) OR (decline_sum + cancel_sum = tx_per_user AND decline_sum > 0) OR (cast(user_risk_status as varchar) ilike '%decline%') THEN '1'
                    END bad_marker1,
                    --marks individual payments as bad indicator for the user
                    CASE
                      WHEN (chargeback_at IS NOT NULL AND chargeback_reason ilike '%Fraud%') OR (p_status = 15) THEN '1'
                    END cb_f_marker,
                    CASE
                      WHEN chargeback_at IS NOT NULL AND (chargeback_reason NOT ilike '%Fraud%' OR chargeback_reason IS NULL) THEN '1'
                    END cb_marker,
                    CASE
                      WHEN (tx_per_user = 1 AND strength = 'Weak') OR (tx_per_user = 1 AND application_name = 'Bender_Auto_Decide') THEN '1'
                    END weak_approve
             FROM (SELECT SUM(decline_count) OVER (PARTITION BY simplex_end_user_id) AS decline_sum,
                          SUM(cancel_count) OVER (PARTITION BY simplex_end_user_id) AS cancel_sum,
                          MAX(CASE WHEN (decline_count = 1 OR cancel_count = 1) THEN p_id END) OVER (PARTITION BY simplex_end_user_id) AS max_decline_cancel_id,
                          MAX(CASE WHEN p_status = 2 THEN p_id END) OVER (PARTITION BY simplex_end_user_id) AS max_approve_id,
                          MAX(p_id) OVER (PARTITION BY simplex_end_user_id) AS last_decision_id,
                          MIN(p_id) OVER (PARTITION BY simplex_end_user_id) AS first_decision_id,
                          *
                   FROM (SELECT p.id p_id,
                                p.simplex_end_user_id,
                                p.status p_status,
                                CASE
                                  WHEN p.status IN (11) AND (strength = 'Strong' OR (strength = 'Weak' AND reason ilike '%Other%') OR application_name ilike '%Bender%') THEN 1
                                  ELSE 0
                                END decline_count,
                                CASE
                                  WHEN (p.status IN (16,18,22,23)) OR (p.status = 11 AND strength = 'Weak' AND reason NOT ilike '%Other%') THEN 1
                                  ELSE 0
                                END cancel_count,
                                rulling.application_name,
                                ruling_id,
                                rulling.decision,
                                rulling.reason,
                                rulling.strength,
                                rulling.user_risk_status,
                                COUNT(*) OVER (PARTITION BY p.simplex_end_user_id) tx_per_user,
                                p.handling_at,
                                p.chargeback_at,
                                p.chargeback_reason
                         FROM payments p
                           LEFT JOIN (SELECT payment_id,
                                             application_name,
                                             max_id AS ruling_id,
                                             decision,
                                             reason,
                                             strength,
                                             user_risk_status
                                      FROM (SELECT *
                                            FROM (SELECT *,
                                                         MAX(id) OVER (PARTITION BY payment_id,application_id) max_id,
                                                         MAX(application_id) OVER (PARTITION BY payment_id) max_application_id
                                                  FROM (SELECT d.payment_id,
                                                               d.id,
                                                               d.application_name,
                                                               d.analytic_code_version,
                                                               d.decision,
                                                               d.reason,
                                                               seu.user_risk_status,
                                                               d.variables#>> '{strength}' strength,
                                                               CASE
                                                                 WHEN d.application_name IN ('EndUser','Scheduler') THEN 6
                                                                 WHEN d.application_name = 'Manual' THEN 5
                                                                 WHEN d.application_name = 'Bender_Auto_Decide' AND d.analytic_code_version IS NOT NULL THEN 4
                                                                 WHEN d.application_name = 'Bender_Auto_Decide' THEN 3
                                                                 WHEN d.application_name = 'Bender' THEN 2
                                                                 ELSE 1
                                                               END application_id
                                                        FROM decisions d
                                                          JOIN payments p ON p.id = d.payment_id
                                                           JOIN simplex_end_users seu ON seu.id = p.simplex_end_user_id
                                                        WHERE d.application_name NOT IN ('Challenger','Nibbler_Challenger')
                                                        
-- You can add some arguments here, possibly like this (this will imporve runing time):
-- and where d.payment_id in (****add something****)
                                                        GROUP BY 1,
                                                                 2,
                                                                 3,
                                                                 4,
                                                                 5,
                                                                 6,
                                                                 7,
                                                                 8,
                                                                 seu.user_risk_status) a) b
                                            WHERE max_application_id = application_id
                                            AND   id = max_id) h
                                      ORDER BY payment_id ASC) rulling ON p.id = rulling.payment_id
                         WHERE rulling.payment_id >= 8847
                         AND   p.status NOT IN (0,1,19,6,20,23)) c) d) e) f) g
-- Add the line below to get a lighter version of the query, this will show all users (each one just once), instead of all payments in the original version. This is useful if you care about the labeling of each user:
-- where p_id in (select distinct max(id) over (partition by simplex_end_user_id) as max_p_id from payments where simplex_end_user_id is not null and status not in (0,1, 19, 6, 20))
;


GRANT ALL PRIVILEGES ON v_label_user TO analyst, simplexcc, application,playground_updater;
alter view v_label_user OWNER to application;

-- run as simplexcc
drop materialized view vm_label_user;
create materialized view vm_label_user as select * from v_label_user;
CREATE INDEX vm_label_user_simplex_end_user_id_idx ON vm_label_user (simplex_end_user_id);
CREATE INDEX vm_label_user_p_id_idx ON vm_label_user (p_id);
GRANT ALL PRIVILEGES ON vm_label_user TO analyst, simplexcc, application, playground_updater;
alter materialized view vm_label_user owner to playground_updater;
select * from vm_label_user limit 50;
