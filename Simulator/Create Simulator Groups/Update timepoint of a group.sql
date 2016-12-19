
-- UPDATE TIMEPOINT OF A GROUP
update simulator_parameters set time_point = time_point - interval '2 minutes' where group_id =135;
commit;

