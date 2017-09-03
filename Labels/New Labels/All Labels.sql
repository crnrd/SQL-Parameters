drop materialized view mv_all_labels cascade;
-- select distinct payment_id, count(*) from 
<<<<<<< HEAD
COMMIT;

CREATE materialized view mv_all_labels

(payment_id,r_payment_id,first_decision,last_decision,last_state,user_label, user_master_label) AS 
     SELECT*
     FROM (SELECT DISTINCT ON (payment_id) pfd.payment_id,
                  rp.id AS r_payment_id,
                  pfd.payment_label AS first_decision,
                  pld.payment_label AS last_decision,
                  pls.payment_label AS last_state,
                  ul.user_label AS user_label,
                  uml.user_master_label as user_master_label
           FROM mv_payment_first_decision_label pfd
             LEFT JOIN mv_payment_last_decision_label pld ON pld.payment_id = pfd.payment_id
             LEFT JOIN mv_payment_last_state_label pls ON pls.payment_id = pfd.payment_id
             LEFT JOIN payments p ON p.id = pfd.payment_id
             LEFT JOIN mv_user_label ul ON ul.email = p.email
             LEFT JOIN mv_user_master_label uml ON uml.email = ul.email
             LEFT JOIN r_payments rp ON rp.simplex_payment_id = pfd.payment_id) all_labels ;

=======
commit;
create materialized view mv_all_labels 
(payment_id, 
first_decision, 
last_decision,
last_state,
user_label)
as 
select * from 
(
select 
distinct on (payment_id)
pfd.payment_id,
pfd.payment_label as first_decision, 
pld.payment_label as last_decision,
pls. payment_label as last_state,
ul.user_label as user_label


from mv_payment_first_decision_label pfd 
left join mv_payment_last_decision_label pld on pld.payment_id = pfd.payment_id 
left join mv_payment_last_state_label pls on pls.payment_id = pfd.payment_id
left join payments p on p.id = pfd.payment_id
left join mv_user_label ul on ul.email = p.email
) all_labels;
>>>>>>> 0554f2fe135ffcf2f7202762f7923020a9509cf6
-- group by 1 having count(*) > 2
-- where last_decision is null or first_decision is null or last_state is null
-- where payment_id = 777562
-- order by 1 desc limit 50;
COMMIT;

SELECT COUNT(*)
FROM ma_view_payment_first_decision_label;

SELECT *
FROM mv_payment_last_state_label
WHERE payment_id = 695037;

SELECT *
FROM mv_all_labels
WHERE payment_id = 601733
ORDER BY 1 DESC LIMIT 50;

select * from r_payments where simplex_payment_id = 915915 ;
