WbVarDef first_sim='$[?first_sim]';
WbVarDef second_sim ='$[?second_sim]';
WbVarDef var1 ='$[?var1]';
WbVarDef payment1 ='$[?payment1]';

--@Wbresult difference in decisions (count)
select real_dec, sim_dec, real_reason, sim_reason, count(*) from (
SELECT first_sim.payment_id,
      second_sim.decision AS real_dec,
      first_sim.decision sim_dec,
      second_sim.reason real_reason,
      first_sim.reason sim_reason
FROM (select sr.*, sp.payment_id, sp.time_point from simulator_results sr 
left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN ($[first_sim])) first_sim
left join (select sr.*, sp.payment_id from simulator_results sr 
left join simulator_parameters sp  on sr.parameter_id = sp.id where run_id  IN ($[second_sim])) second_sim on 
first_sim.payment_id = second_sim.payment_id)a
where real_reason != sim_reason
group by 1, 2, 3, 4
;

--@Wbresult difference in decisions (all)
select payment_id, real_dec, sim_dec, real_reason, sim_reason from (
SELECT first_sim.payment_id,
      second_sim.decision AS real_dec,
      first_sim.decision sim_dec,
      second_sim.reason real_reason,
      first_sim.reason sim_reason
FROM (select sr.*, sp.payment_id, sp.time_point from simulator_results sr 
left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN ($[first_sim])) first_sim
left join (select sr.*, sp.payment_id from simulator_results sr 
left join simulator_parameters sp  on sr.parameter_id = sp.id where run_id  IN ($[second_sim])) second_sim on 
first_sim.payment_id = second_sim.payment_id)a
where real_reason != sim_reason
and real_reason not like 'random_approve%'
and sim_reason not like  'random_approve%'
;

--@Wbresult difference in variables (count)
SELECT key, first_sim_value, second_sim_value, count(*)
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
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN ($[first_sim])
            ) d)s) Challenger
        inner JOIN (SELECT payment_id,
                          KEY,
                          value AS Champion_Value
                   FROM (SELECT payment_id,
                         (jsonb_each_text(variables#> '{Analytic}')). *
                  FROM(
                  select sr.*, sp.payment_id, sp.time_point from simulator_results sr 
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN ($[second_sim])
               ) z)t) Champion
               ON (Challenger.payment_id = Champion.payment_id
                  AND Challenger.key = Champion.key)
WHERE 
challenger_value is null
or champion_value is null
or 
(lower (challenger_value) !=lower (champion_value)
and Challenger.key not in ('num_non_us_ca', 'variable_for_random_approve_all_num_non_us_ca_0_65_threshold'))
) s
group by 1, 2, 3
order by 1, 2, 3;

--@Wbresult difference in variables (all)
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
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN ($[first_sim])
            ) d)s) Challenger
        inner JOIN (SELECT payment_id,
                          KEY,
                          value AS Champion_Value
                   FROM (SELECT payment_id,
                         (jsonb_each_text(variables#> '{Analytic}')). *
                  FROM(
                  select sr.*, sp.payment_id, sp.time_point from simulator_results sr 
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN ($[second_sim])
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
             Challenger_value,
             Champion_value
      FROM (SELECT payment_id,
                   KEY,
                   value AS Challenger_value
            FROM (SELECT payment_id,
                         (jsonb_each_text(variables#> '{Analytic}')). *
                  FROM(
                  
                  select sr.*, sp.payment_id, sp.time_point from simulator_results sr 
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN ($[first_sim])
            ) d)s) Challenger
        LEFT JOIN (SELECT payment_id,
                          KEY,
                          value AS Champion_Value
                   FROM (SELECT payment_id,
                         (jsonb_each_text(variables#> '{Analytic}')). *
                  FROM(
                  select sr.*, sp.payment_id, sp.time_point from simulator_results sr 
                  left join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN ($[second_sim])
               ) z)t) Champion
               ON (Challenger.payment_id = Champion.payment_id
                  AND Challenger.key = Champion.key)
WHERE ((lower (challenger_value) !=lower (champion_value))
or challenger_value is null
or champion_value is null)
and Challenger.key in ('$[var1]')
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
join simulator_parameters sp on sr.parameter_id = sp.id where run_id  IN ($[first_sim])) first_sim
join (select sr.*, sp.payment_id from simulator_results sr 
join simulator_parameters sp  on sr.parameter_id = sp.id where run_id  IN ($[second_sim])) second_sim on 
first_sim.payment_id = second_sim.payment_id)a
where payment_id in ($[payment1])
;

select * from selfie_kyc_exif order by 1 desc limit 50;
select distinct (exif_data ->> 'Image Model') from selfie_kyc_exif;
select * from ghiro order by 1 desc limit 50;
select * from ghiro  where (gexiv #>> '{Exif, GPS is not null order by 1 desc limit 50;
select distinct (gexiv #>> '{Exif, DateTimeOriginal}') from ghiro order by 1 desc limit 50;
