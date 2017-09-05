
--@Wbresult difference in decisions (count)
select first_dec, second_dec, first_reason, second_reason,
--if you want to see an example payment_id for each unique difference, comment-out "count(*)" below, and comment-in "max(payment_id)"
count(*)
--max(payment_id) as max_payment_id
from (
SELECT first_sim.payment_id,
      first_sim.decision as first_dec,
      second_sim.decision AS second_dec,
      first_sim.reason as first_reason,
      second_sim.reason as second_reason


FROM (select sr.*, sp.payment_id, sp.time_point from simulator_results sr
left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN (:first_sim)) first_sim
left join (select sr.*, sp.payment_id from simulator_results sr
left join simulator_parameters sp  on sr.parameter_id = sp.id where run_id  IN (:second_sim)) second_sim on
first_sim.payment_id = second_sim.payment_id)a
where first_reason != second_reason
group by 1, 2, 3, 4
;

--@Wbresult difference in decisions (all)
select payment_id, first_dec, second_dec, first_reason, second_reason from (
SELECT first_sim.payment_id,
      first_sim.decision AS first_dec,
      second_sim.decision AS second_dec,
      first_sim.reason first_reason,
      second_sim.reason second_reason

FROM (select sr.*, sp.payment_id, sp.time_point from simulator_results sr
left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN (:first_sim)) first_sim
left join (select sr.*, sp.payment_id from simulator_results sr
left join simulator_parameters sp  on sr.parameter_id = sp.id where run_id  IN (:second_sim)) second_sim on
first_sim.payment_id = second_sim.payment_id)a
where first_reason != second_reason
and first_reason not like 'random_approve%'
and second_reason not like  'random_approve%'
;

--@Wbresult difference in variables (count)
SELECT key, first_sim_value, second_sim_value,
--if you want to see an example payment_id for each unique difference, comment-out "count(*)" below, and comment-in "max(payment_id)"
count(*)
--max(payment_id) as max_payment_id
FROM (
SELECT Challenger.payment_id,
             Challenger.key,
             Challenger_value as first_sim_value,
             Champion_value as second_sim_value
      FROM (SELECT payment_id,
                   KEY,
                   value AS Challenger_value
            FROM (SELECT payment_id,
                         (jsonb_each_text(variables#> '{Analytic}')). *
                  FROM(

                  select sr.*, sp.payment_id, sp.time_point from simulator_results sr
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN (:second_sim)
            ) d)s) Challenger
        inner JOIN (SELECT payment_id,
                          KEY,
                          value AS Champion_Value
                   FROM (SELECT payment_id,
                         (jsonb_each_text(variables#> '{Analytic}')). *
                  FROM(
                  select sr.*, sp.payment_id, sp.time_point from simulator_results sr
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN (:first_sim)
               ) z)t) Champion
               ON (Challenger.payment_id = Champion.payment_id
                  AND Challenger.key = Champion.key)
WHERE
challenger_value is null
or champion_value is null
or
(lower (challenger_value) !=lower (champion_value)
and Challenger.key not in ('num_non_us_ca', 'variable_for_random_approve_all_num_non_us_ca_0_65_threshold',
'random_value_for_control_group','whitepages_v3_row_id','num_all',
'payment_model_score','card_verification_degree','variable_for_approve_payment_model_score_low_threshold',
'variable_for_random_approve','variable_for_random_approve_num_all_high_threshold','variable_for_random_approve_num_all_low_threshold'))
) s
group by 1, 2, 3
order by 1, 2, 3;

--@Wbresult difference in variables (all)
SELECT Challenger.payment_id,
             Challenger.key,
             Champion_value as first_sim_value,
             Challenger_value as second_sim_value
      FROM (SELECT payment_id,
                   KEY,
                   value AS Challenger_value
            FROM (SELECT payment_id,
                         (jsonb_each_text(variables#> '{Analytic}')). *
                  FROM(

                  select sr.*, sp.payment_id, sp.time_point from simulator_results sr
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN (:second_sim)
            ) d)s) Challenger
        inner JOIN (SELECT payment_id,
                          KEY,
                          value AS Champion_Value
                   FROM (SELECT payment_id,
                         (jsonb_each_text(variables#> '{Analytic}')). *
                  FROM(
                  select sr.*, sp.payment_id, sp.time_point from simulator_results sr
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN (:first_sim)
               ) z)t) Champion
               ON (Challenger.payment_id = Champion.payment_id
                  AND Challenger.key = Champion.key)
WHERE
challenger_value is null
or champion_value is null
or
(lower (challenger_value) !=lower (champion_value)
and Challenger.key not in ('num_non_us_ca', 'variable_for_random_approve_all_num_non_us_ca_0_65_threshold'))
;

--@Wbresult specific variable
SELECT payment_id, key, Challenger_value as first_sim, Champion_value as second_sim
FROM (
SELECT Challenger.payment_id,
             Challenger.key,
             Champion_value,
             Challenger_value
      FROM (SELECT payment_id,
                   KEY,
                   value AS Challenger_value
            FROM (SELECT payment_id,
                         (jsonb_each_text(variables#> '{Analytic}')). *
                  FROM(

                  select sr.*, sp.payment_id, sp.time_point from simulator_results sr
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN (:second_sim)
            ) d)s) Challenger
        LEFT JOIN (SELECT payment_id,
                          KEY,
                          value AS Champion_Value
                   FROM (SELECT payment_id,
                         (jsonb_each_text(variables#> '{Analytic}')). *
                  FROM(
                  select sr.*, sp.payment_id, sp.time_point from simulator_results sr
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN (:first_sim)
               ) z)t) Champion
               ON (Challenger.payment_id = Champion.payment_id
                  AND Challenger.key = Champion.key)
WHERE ((lower (challenger_value) !=lower (champion_value))
or challenger_value is null
or champion_value is null)
and Challenger.key in (:var1)
) s
order by 1, 2, 3;


--@Wbresult a certain payment
select payment_id, time_point, first_sim_dec, second_sim_dec, first_sim_reason, second_sim_reason from (
SELECT first_sim.payment_id,
      second_sim.decision AS second_sim_dec,
      first_sim.decision first_sim_dec,
      second_sim.reason second_sim_reason,
      first_sim.reason first_sim_reason,
      time_point
FROM (select sr.*, sp.payment_id, sp.time_point from simulator_results sr
join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN (:first_sim)) first_sim
join (select sr.*, sp.payment_id from simulator_results sr
join simulator_parameters sp  on sr.parameter_id = sp.id where run_id  IN (:second_sim)) second_sim on
first_sim.payment_id = second_sim.payment_id)a
where payment_id in (:payment1)
;


