WbVarDef nibbler_code_version = '$[?challanger_version]'; 
WbVarDef champ_code_version = '$[?champion_version]';


--@WbResult Nibbler Champ vs Champion difference - count 1
Select decision_challenger, decision_champion, reason_challenger, reason_champion, count(*) from
(
SELECT Challenger.payment_id, 
				Challenger.decision decision_challenger,
				Champion.decision decision_champion, 
				Challenger.reason reason_challenger, 
				Champion.reason reason_champion
FROM(
      SELECT distinct on (r_payment_id) r_payment_id as payment_id, variables #>> '{Analytic, decision}' decision,
 			             variables #>> '{Analytic, reason}' reason
                  FROM decisions
                  WHERE application_name = 'Nibbler_Post_Auth_Offline_Challenger'
                  and variables #>> '{Analytic, analytic_code_version}' in ('$[challanger_version]')                  
			)Challenger
      left JOIN (SELECT DISTINCT on (r_payment_id) r_payment_id as payment_id,
 			             variables #>> '{Analytic, decision}' decision,
 			             ltrim (variables #>> '{Analytic, reason}') reason
                   FROM decisions
                         WHERE application_name = 'Bender_Post_Auth_Offline'
                  and variables #>> '{Analytic, analytic_code_version}' in ('$[champion_version]')                                                                  
                  ) Champion
                         
               ON (Challenger.payment_id = Champion.payment_id))x
where reason_challenger != reason_champion

group by 1,2,3,4
order by 1,2,3,4
;

--@WbResult Nibbler Champ/Challenge difference in decision full results
select * from (
SELECT Challenger.payment_id, 
				Challenger.decision decision_challenger,
				Champion.decision decision_champion, 
				Challenger.reason reason_challenger, 
				Champion.reason reason_champion
FROM(
      SELECT distinct on (r_payment_id) r_payment_id as payment_id, variables #>> '{Analytic, decision}' decision,
 			             variables #>> '{Analytic, reason}' reason
                  FROM decisions
                  WHERE application_name = 'Nibbler_Post_Auth_Offline_Challenger'
                  and variables #>> '{Analytic, analytic_code_version}' in ('$[challanger_version]')              
			)Challenger
      left JOIN (SELECT DISTINCT on (r_payment_id) r_payment_id as payment_id,
 			             variables #>> '{Analytic, decision}' decision,
 			             ltrim (variables #>> '{Analytic, reason}') reason
                   FROM decisions
                         WHERE application_name = 'Bender_Post_Auth_Offline'
                  and variables #>> '{Analytic, analytic_code_version}' in ('$[champion_version]')                                      
) Champion
                         
               ON (Challenger.payment_id = Champion.payment_id))x
where reason_challenger != reason_champion
order by reason_challenger
;

--@WbResult Nibbler Champ/challenge diff in variables full results

SELECT *
FROM (
SELECT Challenger.r_payment_id,
             Challenger.key,
             Challenger_value,
             Champion_value
      FROM (SELECT DISTINCT r_payment_id,
                   KEY,
                   value AS Challenger_value
            FROM (SELECT r_payment_id,
                         (jsonb_each_text(variables#> '{Analytic,variables, Analytic}')). *
                  FROM decisions
                  WHERE application_name = 'Nibbler_Post_Auth_Offline_Challenger'
                  and variables #>> '{Analytic, analytic_code_version}' in ('$[challanger_version]')                
						) d) Challenger
        LEFT JOIN (SELECT DISTINCT r_payment_id,
                          KEY,
                          value AS Champion_Value
                   FROM (SELECT r_payment_id,
                         (jsonb_each_text(variables#> '{Analytic,variables, Analytic}')). *
                         FROM decisions
                  WHERE application_name = 'Bender_Post_Auth_Offline'
                  and variables #>> '{Analytic, analytic_code_version}' in ('$[champion_version]')               
							 ) z) Champion
               ON (Challenger.r_payment_id = Champion.r_payment_id
									AND Challenger.key = Champion.key)
WHERE (lower (challenger_value) !=lower (champion_value)) 
and Challenger.key not in ('variable_for_random_approve', 
'variable_for_random_approve_num_all_high_threshold',
'variable_for_approve_payment_model_score_low_threshold',
'random_value_for_control_group',
'card_verification_degree')


) s
order by key;

--@WbResult Nibbler Champ/challenge diff in variables - count

SELECT key, Challenger_value, Champion_value, count(*)
FROM (
SELECT Challenger.r_payment_id,
             Challenger.key,
             Challenger_value,
             Champion_value
      FROM (SELECT DISTINCT r_payment_id,
                   KEY,
                   value AS Challenger_value
            FROM (SELECT r_payment_id,
                         (jsonb_each_text(variables#> '{Analytic,variables, Analytic}')). *
                  FROM decisions
                  WHERE application_name = 'Nibbler_Post_Auth_Offline_Challenger'
                  and variables #>> '{Analytic, analytic_code_version}' in ('$[challanger_version]')                    
						) d) Challenger
        LEFT JOIN (SELECT DISTINCT r_payment_id,
                          KEY,
                          value AS Champion_Value
                   FROM (SELECT r_payment_id,
                         (jsonb_each_text(variables#> '{Analytic,variables, Analytic}')). *
                         FROM decisions
                  WHERE application_name = 'Bender_Post_Auth_Offline'
                  and variables #>> '{Analytic, analytic_code_version}' in ('$[champion_version]')              
							 ) z) Champion
               ON (Challenger.r_payment_id = Champion.r_payment_id
									AND Challenger.key = Champion.key)
WHERE (lower (challenger_value) !=lower (champion_value))
and Challenger.key not in ('variable_for_random_approve', 
'variable_for_random_approve_num_all_high_threshold',
'variable_for_approve_payment_model_score_low_threshold',
'random_value_for_control_group',
'card_verification_degree')
) s
group by 1, 2, 3
order by 1, 2, 3;


select * from decisions where application_name = 'Nibbler_Post_Auth_Offline_Challenger' order by 1 desc limit 50;


select * from decisions order by 1 desc limit 50;
