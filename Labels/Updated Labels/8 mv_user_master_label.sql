drop materialized view mv_new_user_label cascade;
commit;
create materialized view mv_user_master_label (email, user_master_label)
as 

-- commit;
with 
p_ids  as (select id, email from payments where status in (2, 13, 15,  11, 16, 22)
-- and  id < 810000 
)

select email,
case 
when user_label in ('fraudalent_user', 'urs_decline' , 'bad_user' , 'auto_declined') then 'bad'
when user_label in ('good_user' , 'approved_user_cancelled_last_payment', 'approved_by_analyst' , 'auto_approved') then 'good'
else 'other' end as user_master_label

from 
mv_user_label ul 
where ul.email in (select email from p_ids) 

;
commit;
select distinct user_label, count(*) from mv_new_user_label group by 1;
select * from user_summary order by 1 desc limit 50;



