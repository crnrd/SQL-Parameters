

-- Payments table
-- @WbResult payment_events_full
SELECT count(*)
FROM r_payment_events
WHERE (payment_id IN (:p_ids))

ORDER BY 1 DESC;


-- Partner seller snaps
-- @WbResult partner_seller_events_snap
SELECT count(*)
FROM r_partner_seller_snap_events 
WHERE seller_id IN (SELECT partner_seller_id FROM r_payment_events WHERE payment_id IN (:p_ids));


--@WbResult buyer emailage
select count(*) from r_payment_events p left join enrich_email_age ea on p.email_raw = ea.email where  payment_id in (:p_ids) 
and ea.data is null;

--@WbResult request emailage
select count(*) from r_payment_events p left join enrich_email_age ea on (p.partner_specific #>> '{payment_request, email}') = ea.email where  payment_id in (:p_ids) 
and ea.data is null;


--@WbResult seller emailage
with seller_data as (select email_raw from r_partner_seller_snap_events where seller_id in (
select partner_seller_id from r_payment_events where payment_id in (:p_ids)))
select count(*) from seller_data sd left join enrich_email_age ea on sd.email_raw = ea.email where 
 ea.data is null;

--@WbResult buyer maxmind
with buyer_data as (select  coalesce((simplex_session #>> '{ip}'), (partner_session #>> '{ip}')) as ip, address1_raw as address1
 from r_payment_events where payment_id in ((:p_ids)) ),
mm_data as (select request_data ->> 'i' as mm_ip, request_data ->> 'shipAddr' as mm_add1, data from enrich_maxmind)
select count(*) from buyer_data bd left join mm_data on bd.ip = mm_data.mm_ip and bd.address1 = mm_data.mm_add1 
where mm_data.data is null;

--@WbResult seller maxmind
with seller_data as (select distinct seller_id, (last_sessions #>> '{0, ip}') as ip, address1_raw as address1
from r_partner_seller_snap_events where seller_id in (
select partner_seller_id from r_payment_events where payment_id in (:p_ids)) group by 1, 2,3),
mm_data as (select request_data ->> 'i' as mm_ip, request_data ->> 'shipAddr' as mm_add1, data from enrich_maxmind)
select count(*) from seller_data sd left join mm_data on sd.ip = mm_data.mm_ip and sd.address1 = mm_data.mm_add1 
where mm_data.data is null;

--@WbResult buyer blocked
with buyer_data as (select payment_id, coalesce((simplex_session #>> '{ip}'), (partner_session #>> '{ip}')) ip from r_payment_events where payment_id in ((:p_ids)))
select * from buyer_data bd 
left join enrich_blocked b on bd.ip = b.ip  
where b.response_data is null order by 1 desc limit 50;
 
;

--@WbResult seller blocked
with seller_data as (select distinct seller_id, (last_sessions #>> '{0, ip}')  ip from r_partner_seller_snap_events where seller_id in (
select partner_seller_id from r_payment_events where payment_id in (:p_ids)) group by 1, 2)
select count(*) from seller_data left join enrich_blocked b on seller_data.ip = b.ip  where b.response_data is null
;

--@WbResult buyer whitepages
with buyer_data as (select coalesce((simplex_session #>> '{ip}'), (partner_session #>> '{ip}')) ip, first_name_raw as first_name from r_payment_events where payment_id in ((:p_ids))
and country_raw in ('US', 'CA'))
select count(*) from buyer_data bd left join enrich_whitepages_v3 wp on bd.ip = wp.request_data ->> 'ip_address'
and bd.first_name =  wp.request_data ->> 'firstname'
 where data is null;

--@WbResult seller whitepages
with seller_data as (select distinct seller_id,  (last_sessions #>> '{0, ip}') ip, first_name_raw as first_name  from r_partner_seller_snap_events where seller_id in (
select partner_seller_id from r_payment_events where payment_id in (:p_ids)) and country_raw in ('US', 'CA') group by 1, 2, 3 )
select count(*) from seller_data sd left join enrich_whitepages_v3 wp on sd.ip = wp.request_data ->> 'ip_address'
and sd.first_name =  wp.request_data ->> 'firstname'
 where data is null;


