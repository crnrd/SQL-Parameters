-- select distinct payment_id, count(*) from 
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
-- group by 1 having count(*) > 2
-- where last_decision is null or first_decision is null or last_state is null
-- where payment_id = 777562
-- order by 1 desc limit 50;
commit;
select count(*) from ma_view_payment_first_decision_label;

;

select * from mv_payment_last_state_label where payment_id = 695037;

select * from mv_new_all_labels  where payment_id =601733         order by 1 desc limit 50;



