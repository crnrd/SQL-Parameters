




select distinct old_user, payment_chargeback,  count(*) 
from (

select *, lf.ride_id, 
case when user_rating::float between 4.6 and 4.9 then 1 else 0 end as good_rating_not_new,
case when seller_rating::float between 4.6 and 4.9 then 1 else 0 end as seller_good_rating_not_new,
case when user_rating::float < 4 then 1 else 0 end as low_rating,
case when seller_rating::float < 4 then 1 else 0 end as seller_low_rating,
case when payment_method = 'coupon' then 1 else 0 end as coupon, 
case when is_business_user = 'true' then 1 else 0 end as business_user, 
case when cvv_result_code != 'pass' then 1 else 0 end as cvv_not_pass,
case when (session_timestamp - user_creation_date) > interval '365 days'  then 1 else 0 end as old_user,
case when (session_timestamp - seller_creation_date) > interval '7 days'  then 1 else 0 end as old_seller
from lyft_test_normalized lf
left join on lyft_datasets ld
on lf.ride_id = ld.ride_id
where data_set = 'train' ) a
where old_user = 1 and business_user = 1
group by 1,2 order by 1, 2
 desc limit 50;
 
select distinct user_id, count (ride_id) from lyft_new_normalized group by 1 order by 2 desc limit 50;

select * 
