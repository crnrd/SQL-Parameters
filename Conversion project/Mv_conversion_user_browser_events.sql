SELECT
  distinct on (payment_id)
  payment_id,
  event_type,
  *
from
  user_browser_events
where
  payment_id > 1537836
order by payment_id, id asc
limit 10;


select * from user_browser_events where payment_id = 1537838 order by 1 asc;