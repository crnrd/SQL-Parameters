

select distinct status, count(*) over () as total,
 count(*) over (partition by status) as num_per_status,
100* count(*) over (partition by status)::float /count(*) over () as perc
  from payments
  where status in (2, 11, 16, 13, 15, 22) and id between 200000 and 600000;
  

