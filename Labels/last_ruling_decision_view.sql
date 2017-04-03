create view v_label_last_ruling_decision as 
select
            application_name, payment_id, decision, reason,
            variables #> '{strength}' as strength, variables #> '{verification_type}' as verification_type
        from decisions where id in (select max_id from (
            select * from (
                select *, max(id) over (PARTITION BY payment_id, application_id) max_id, max(application_id)
                over (PARTITION BY payment_id) max_application_id from (
                    select d.payment_id, d.id, d.application_name, d.analytic_code_version,
                        case when d.application_name = 'Offline Manual' then 8
                             when d.application_name in ('EndUser', 'Scheduler') then 7
                             when d.application_name = 'Manual' then 6
                             when d.application_name = 'Nibbler_post_kyc' and d.analytic_code_version is not null then 5
                             when d.application_name = 'Bender_Auto_Decide' and d.analytic_code_version is not null then 4
                             when d.application_name = 'Bender_Auto_Decide' then 3
                             when d.application_name = 'Bender' then 2
                             else 1 end application_id
                    from decisions d
                    where d.created_at < %s and d.payment_id in (%s) and not (d.application_name in ('Manual',
                    'Offline Manual') and d.decision not in
                    ('approved', 'declined', 'cancelled'))
                    and d.application_name in ('EndUser', 'Scheduler', 'Manual', 'Offline Manual',
                    'Bender_Auto_Decide', 'Bender')
                    group by d.payment_id, d.id, d.application_name, d.analytic_code_version
                )a
            )b
        where max_application_id = application_id and id=max_id)h)
        order by payment_id asc;

GRANT ALL PRIVILEGES ON v_label_last_ruling_decision TO analyst, simplexcc, application;
