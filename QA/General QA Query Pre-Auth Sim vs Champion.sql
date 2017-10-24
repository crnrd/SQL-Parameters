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
             decision,
             reason,
             sp.time_point
           FROM
             simulator_results sr,
             simulator_parameters sp
           WHERE sr.run_id = :run_id
                 AND sr.parameter_id = sp.id


         ) Challenger
      LEFT JOIN (SELECT DISTINCT ON (payment_id)
                   r_payment_id,
                   variables #>> '{Analytic, decision}'      decision,
                   ltrim(variables #>> '{Analytic, reason}') reason,
                   executed_at
                 FROM vm_decisions_two_days
                 WHERE application_name = 'Bender_Pre_Auth_Decide'
                       AND variables #>> '{Analytic, analytic_code_version}' IN (:champion_version)
                ) Champion

        ON (Challenger.payment_id = Champion.r_payment_id AND Challenger.time_point = Champion.executed_at)) x
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
                decision,
                reason,
                sp.time_point
              FROM
                simulator_results sr,
                simulator_parameters sp
              WHERE sr.run_id = :run_id
                    AND sr.parameter_id = sp.id
            ) Challenger
         LEFT JOIN (SELECT DISTINCT ON (payment_id)
                      r_payment_id,
                      variables #>> '{Analytic, decision}'      decision,
                      ltrim(variables #>> '{Analytic, reason}') reason,
                      executed_at
                    FROM vm_decisions_two_days
                    WHERE application_name = 'Bender_Pre_Auth_Decide'
                          AND variables #>> '{Analytic, analytic_code_version}' IN (:champion_version)
                   ) Champion

           ON (Challenger.payment_id = Champion.r_payment_id AND Challenger.time_point = Champion.executed_at)) x
WHERE reason_challenger != reason_champion
ORDER BY reason_challenger;

--@WbResult Nibbler Champ/challenge diff in variables full results

SELECT *
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
               time_point
             FROM (SELECT
                     payment_id,
                     sp.time_point,
                     (jsonb_each_text(variables #> '{Analytic}')).*
                   FROM
                     simulator_results sr,
                     simulator_parameters sp
                   WHERE sr.run_id = :run_id
                         AND sr.parameter_id = sp.id
                  ) d) Challenger
         LEFT JOIN (SELECT DISTINCT
                      r_payment_id,
                      KEY,
                      value AS Champion_Value,
                      executed_at
                    FROM (SELECT
                            r_payment_id,
                            executed_at,
                            (jsonb_each_text(variables #> '{Analytic,variables, Analytic}')).*
                          FROM vm_decisions_two_days
                          WHERE application_name = 'Bender_Pre_Auth_Decide'
                                AND variables #>> '{Analytic, analytic_code_version}' IN (:champion_version)
                         ) z) Champion
           ON (Challenger.payment_id = Champion.r_payment_id
               AND Challenger.key = Champion.key
               AND Challenger.time_point = Champion.executed_at)
       WHERE (lower(challenger_value) != lower(champion_value))
             AND Challenger.key NOT IN ('variable_for_random_approve',
                                        'variable_for_random_approve_num_all_high_threshold',
                                        'variable_for_approve_payment_model_score_low_threshold',
                                        'random_value_for_control_group',
                                        'card_verification_degree')


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
               time_point
             FROM (SELECT
                     payment_id,
                     time_point,
                     (jsonb_each_text(variables #> '{ Analytic}')).*
                   FROM
                     simulator_results sr,
                     simulator_parameters sp
                   WHERE sr.run_id = :run_id
                         AND sr.parameter_id = sp.id
                  ) d) Challenger
         LEFT JOIN (SELECT DISTINCT
                      r_payment_id,
                      KEY,
                      executed_at,
                      value AS Champion_Value
                    FROM (SELECT
                            r_payment_id,
                            executed_at,
                            (jsonb_each_text(variables #> '{Analytic,variables, Analytic}')).*
                          FROM vm_decisions_two_days
                          WHERE application_name = 'Bender_Pre_Auth_Decide'
                                AND variables #>> '{Analytic, analytic_code_version}' IN (:champion_version)
                         ) z) Champion
           ON (Challenger.payment_id = Champion.r_payment_id
               AND Challenger.key = Champion.key
               AND Challenger.time_point = Champion.executed_at)
       WHERE (lower(challenger_value) != lower(champion_value)) AND
             Challenger.key NOT IN ('variable_for_random_approve',
                                    'variable_for_random_approve_num_all_high_threshold',
                                    'variable_for_approve_payment_model_score_low_threshold',
                                    'random_value_for_control_group',
                                    'card_verification_degree')
     ) s
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;



