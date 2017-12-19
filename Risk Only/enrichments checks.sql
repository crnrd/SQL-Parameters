
-- Payments table
-- @WbResult payment_events_full
SELECT *
FROM r_payment_events
WHERE (payment_id IN (:p_ids))

ORDER BY id DESC;


-- Partner seller snaps
-- @WbResult partner_seller_events_snap
SELECT *
FROM r_partner_seller_snap_events 
WHERE seller_id IN (SELECT partner_seller_id FROM r_payment_events WHERE payment_id IN (:p_ids));


--@WbResult buyer emailage
select * from enrich_email_age where email in (select email_raw from r_payment_events where payment_id in (:p_ids));

--@WbResult request emailage
select * from enrich_email_age where email in (select partner_specific #>> '{payment_request, email}' from r_payment_events where payment_id in (:p_ids));

--@WbResult seller emailage
with seller_data as (select * from r_partner_seller_snap_events where seller_id in (
select partner_seller_id from r_payment_events where payment_id in (:p_ids)))
select * from enrich_email_age where email in (select email_raw from seller_data);





--@WbResult buyer maxmind
with buyer_data as (select * from r_payment_events where payment_id in ((:p_ids)))
select * from enrich_maxmind where request_data ->> 'i' in 
(select coalesce((simplex_session #>> '{ip}'), (partner_session #>> '{ip}')) from buyer_data)
and request_data ->> 'shipAddr' in (select address1_raw from buyer_data);

--@WbResult seller maxmind
with seller_data as (select * from r_partner_seller_snap_events where seller_id in (
select partner_seller_id from r_payment_events where payment_id in (:p_ids)))
select * from enrich_maxmind where request_data ->> 'i' in (select (last_sessions #>> '{0, ip}') from seller_data)
and request_data ->> 'shipAddr' in (select address1_raw from seller_data);

--@WbResult buyer blocked
with buyer_data as (select * from r_payment_events where payment_id in ((:p_ids)))
select * from enrich_blocked where ip in
 (select coalesce((simplex_session #>> '{ip}'), (partner_session #>> '{ip}')) from buyer_data)
;

--@WbResult seller blocked
with seller_data as (select * from r_partner_seller_snap_events where seller_id in (
select partner_seller_id from r_payment_events where payment_id in (:p_ids)))
select * from enrich_blocked where ip in (select (last_sessions #>> '{0, ip}') from seller_data)
;

--@WbResult buyer whitepages
with buyer_data as (select * from r_payment_events where payment_id in ((:p_ids)))
select * from enrich_whitepages_v3 where request_data ->> 'ip_address' in 
 (select coalesce((simplex_session #>> '{ip}'), (partner_session #>> '{ip}')) from buyer_data)
and request_data ->> 'firstname' in (select first_name_raw from buyer_data);

--@WbResult seller whitepages
with seller_data as (select * from r_partner_seller_snap_events where seller_id in (
select partner_seller_id from r_payment_events where payment_id in (:p_ids)))
select * from enrich_whitepages_v3 where request_data ->> 'ip_address' in (select (last_sessions #>> '{0, ip}') from seller_data)
and request_data ->> 'firstname' in (select first_name_raw from seller_data);



--@WbResult buyer cnam
with buyer_data as (select * from r_payment_events where payment_id in ((:p_ids)))
select * from enrich_opencnam where phone in
 (select phone_raw from buyer_data)
;

--@WbResult seller cnam
with seller_data as (select * from r_partner_seller_snap_events where seller_id in (
select partner_seller_id from r_payment_events where payment_id in (:p_ids)))
select * from enrich_opencnam where phone ilike (select phones_raw ->> 'phone' from seller_data limit 1);

