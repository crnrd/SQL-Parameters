--select * from  vm_decisions_two_days limit 20;
--use the following to update noam's materialized view of decisions for last 2 days
REFRESH MATERIALIZED VIEW vm_decisions_two_days;
--then make sure to replace the decisions table with vm_decisions_two_days in the queries below

-- updated to work in DataGrip

--@WbResult Nibbler Champ vs Champion difference - count 1
SELECT
  decision_challenger,
  decision_champion,
  reason_challenger,
  reason_champion,
  count(*)
FROM
  (
    SELECT
      Challenger.payment_id,
      Challenger.decision decision_challenger,
      Champion.decision   decision_champion,
      Challenger.reason   reason_challenger,
      Champion.reason     reason_champion
    FROM (
           SELECT DISTINCT ON (payment_id)
             payment_id,
             variables #>> '{Analytic, decision}' decision,
             variables #>> '{Analytic, reason}'   reason,
             executed_at
           FROM vm_decisions_two_days
           WHERE application_name = 'Nibbler_Pre_Auth_Challenger'
                 AND variables #>> '{Analytic, analytic_code_version}' IN (:challanger_version)
         ) Challenger
      LEFT JOIN (SELECT DISTINCT ON (payment_id)
                   payment_id,
                   variables #>> '{Analytic, decision}'      decision,
                   ltrim(variables #>> '{Analytic, reason}') reason,
                   executed_at
                 FROM vm_decisions_two_days
                 WHERE application_name = 'Bender_Pre_Auth_Decide'
                       AND variables #>> '{Analytic, analytic_code_version}' IN (:champion_version)
                ) Champion

        ON (Challenger.payment_id = Champion.payment_id AND Challenger.executed_at = Champion.executed_at)) x
WHERE reason_challenger != reason_champion

GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 3, 4;

--@WbResult Nibbler Champ/Challenge difference in decision full results
SELECT *
FROM (
       SELECT
         Challenger.payment_id,
         Challenger.decision decision_challenger,
         Champion.decision   decision_champion,
         Challenger.reason   reason_challenger,
         Champion.reason     reason_champion
       FROM (
              SELECT DISTINCT ON (payment_id)
                payment_id,
                variables #>> '{Analytic, decision}' decision,
                variables #>> '{Analytic, reason}'   reason,
                executed_at
              FROM vm_decisions_two_days
              WHERE application_name = 'Nibbler_Pre_Auth_Challenger'
                    AND variables #>> '{Analytic, analytic_code_version}' IN (:challanger_version)
            ) Challenger
         LEFT JOIN (SELECT DISTINCT ON (payment_id)
                      payment_id,
                      variables #>> '{Analytic, decision}'      decision,
                      ltrim(variables #>> '{Analytic, reason}') reason,
                      executed_at
                    FROM vm_decisions_two_days
                    WHERE application_name = 'Bender_Pre_Auth_Decide'
                          AND variables #>> '{Analytic, analytic_code_version}' IN (:champion_version)
                   ) Champion

           ON (Challenger.payment_id = Champion.payment_id AND Challenger.executed_at = Champion.executed_at)) x
WHERE reason_challenger != reason_champion
ORDER BY reason_challenger;

--@WbResult Nibbler Champ/challenge diff in variables full results

SELECT *
FROM (
       SELECT
         Challenger.payment_id,
         Challenger.key,
         Challenger_value,
         Champion_value,
         Challenger.executed_at,
         Champion.executed_at
       FROM (SELECT DISTINCT
               payment_id,
               KEY,
               value AS Challenger_value,
               executed_at
             FROM (SELECT
                     payment_id,
                     executed_at,
                     (jsonb_each_text(variables #> '{Analytic,variables, Analytic}')).*
                   FROM vm_decisions_two_days
                   WHERE application_name = 'Nibbler_Pre_Auth_Challenger'
                         AND variables #>> '{Analytic, analytic_code_version}' IN (:challanger_version)
                  ) d) Challenger
         LEFT JOIN (SELECT DISTINCT
                      payment_id,
                      KEY,
                      value AS Champion_Value,
                      executed_at
                    FROM (SELECT
                            payment_id,
                            executed_at,
                            (jsonb_each_text(variables #> '{Analytic,variables, Analytic}')).*
                          FROM vm_decisions_two_days
                          WHERE application_name = 'Bender_Pre_Auth_Decide'
                                AND variables #>> '{Analytic, analytic_code_version}' IN (:champion_version)
                         ) z) Champion
           ON (Challenger.payment_id = Champion.payment_id
               AND Challenger.key = Champion.key
               AND Challenger.executed_at = Champion.executed_at)
       WHERE (lower(challenger_value) != lower(champion_value))
             AND Challenger.key NOT IN ('variable_for_random_approve',
                                        'variable_for_random_approve_num_all_high_threshold',
                                        'variable_for_approve_payment_model_score_low_threshold',
                                        'random_value_for_control_group',
                                        'Variable_for_random_approve_under_limit_control_group',
                                        -- These should be removed after challenger pre-auth is fixed
                                        'card_verification_degree',
                                        'avs_match',
                                        'decent_user_nothing_bad',
                                        'good_user_three_ds_avs_match',
                                        'id_match',
                                        'max_user_age_days',
                                        'analyst_will_send_selfie'
                                        'photo_selfie_1',
                                        'three_ds_valid_response',
                                        'user_first_time_non_threeds',
                                        'variable_for_rule_verify_first',
                                        'video_selfie_1',
                                        'was_auth_done_with_threeds')
              and Champion.KEY NOT IN ('analyst_will_send_selfie',
                                       'photo_selfie_1',
                                       'variable_for_random_approve_under_limit_control_group')


     ) s
ORDER BY key;

--@WbResult Nibbler Champ/challenge diff in variables - count


SELECT
  key,
  Challenger_value,
  Champion_value,
  count(*)
FROM (
       SELECT
         Challenger.payment_id,
         Challenger.key,
         Challenger_value,
         Champion_value
       FROM (SELECT DISTINCT
               payment_id,
               KEY,
               value AS Challenger_value,
               executed_at
             FROM (SELECT
                     payment_id,
                     executed_at,
                     (jsonb_each_text(variables #> '{Analytic,variables, Analytic}')).*
                   FROM vm_decisions_two_days
                   WHERE application_name = 'Nibbler_Pre_Auth_Challenger'
                         AND variables #>> '{Analytic, analytic_code_version}' IN (:challanger_version)
                  ) d) Challenger
         LEFT JOIN (SELECT DISTINCT
                      payment_id,
                      KEY,
                      executed_at,
                      value AS Champion_Value
                    FROM (SELECT
                            payment_id,
                            executed_at,
                            (jsonb_each_text(variables #> '{Analytic,variables, Analytic}')).*
                          FROM vm_decisions_two_days
                          WHERE application_name = 'Bender_Pre_Auth_Decide'
                                AND variables #>> '{Analytic, analytic_code_version}' IN (:champion_version)
                         ) z) Champion
           ON (Challenger.payment_id = Champion.payment_id
               AND Challenger.key = Champion.key
               AND Challenger.executed_at = Champion.executed_at)
       WHERE (lower(challenger_value) != lower(champion_value)) AND
             Challenger.key NOT IN ('variable_for_random_approve',
                                    'variable_for_random_approve_num_all_high_threshold',
                                    'variable_for_approve_payment_model_score_low_threshold',
                                    'random_value_for_control_group',
                                    'Variable_for_random_approve_under_limit_control_group',
                                    -- These should be removed after challenger pre-auth is fixed
                                    'card_verification_degree',
                                    'avs_match',
                                    'decent_user_nothing_bad',
                                    'good_user_three_ds_avs_match',
                                    'id_match',
                                    'max_user_age_days',
                                    'analyst_will_send_selfie'
                                    'photo_selfie_1',
                                    'three_ds_valid_response',
                                    'user_first_time_non_threeds',
                                    'variable_for_rule_verify_first',
                                    'video_selfie_1',
                                    'was_auth_done_with_threeds')
              and Champion.KEY NOT IN ('analyst_will_send_selfie',
                                       'photo_selfie_1',
                                       'variable_for_random_approve_under_limit_control_group')
     ) s
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

