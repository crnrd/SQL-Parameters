
SELECT payment_id,time_point,risk_mode ::risk_mode_type as risk_mode,checkpoint_name::checkpoint_name as checkpoint_name
FROM
       simulator_parameters WHERE group_id in (3094,3096,3062);
