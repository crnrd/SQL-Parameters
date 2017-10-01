WbVarDef my_query = 'select 
distinct label, sum(mm_proxy_score) as mm_proxy_score, sum (  mm_anonymous_proxy) as  mm_anonymous_proxy, sum(blocked) as blocked, sum(radar) as radar, sum (corporate) as corporate,
sum(riskscore) as riskscore

 from 
(select status, 
case when p.id in (select distinct payment_id from verification_requests where requesting_user_id != -1) then 'verify'
         when status in (2,13) then 'approved'
         when status = 11 then 'declined'
    end "label",

case when (cast(maxmind ->> 'proxyScore' as float)) > 0  then 1 else 0 end as mm_proxy_score,
case when (maxmind->>'anonymousProxy') ilike '%YES%' then 1 else 0 end as mm_anonymous_proxy,
case when (blocked #>> '{ip, blocked}') ilike '%YES%' then 1 else 0 end as blocked, 
case when ((pd.data #>> '{main, strict, diff}')::FLOAT *1000.0::numeric > 25)
and ((maxmind ->> 'ip_netSpeedCell') ilike '%Cellular%')
and (blocked #>> '{ip, blocked}') ilike '%NO%'
and ((maxmind->>'anonymousProxy') ilike '%NO%')
and ((cast(maxmind ->> 'proxyScore' as float)) = 0)
then 1 else 0 end as radar,
case when maxmind ->> 'ip_netSpeedCell' ilike '%Corporate%' then 1 else 0 end as corporate,
case when (maxmind ->> 'riskScore')::float >= 70 then 1 else 0 end as riskscore
from payments p
left join proxy_detection pd on p.payment_id = pd.payment_id
where p.id > 18000 
and  (cast(maxmind ->> 'distance' as float)) < 60
and p.id not in (select distinct payment_id from verification_requests where requesting_user_id = -1)) a where label != '' group by 1 order by label';

explain analyze
select * from ($[my_query]) as b;



WbVarDef mm_proxy_score_approved,mm_anonymous_proxy_approved, blocked_approved, radar_approved, corporate_approved, riskscore_approved = @"select mm_proxy_score, mm_anonymous_proxy, blocked,radar, corporate, riskscore from ($[my_query]) as b where label = 'approved'";
WbVarDef mm_proxy_score_declined,mm_anonymous_proxy_declined, blocked_declined, radar_declined, corporate_declined, riskscore_declined = @"select mm_proxy_score, mm_anonymous_proxy, blocked,radar, corporate, riskscore from ($[my_query]) as b where label = 'declined'";
WbVarDef mm_proxy_score_verify,mm_anonymous_proxy_verify, blocked_verify, radar_verify, corporate_verify, riskscore_verify = @"select mm_proxy_score, mm_anonymous_proxy, blocked,radar, corporate, riskscore from ($[my_query]) as b where label = 'verify'";

--@WbResult statistics

select (($[mm_proxy_score_declined] + $[mm_proxy_score_verify])::float/($[mm_proxy_score_approved] + $[mm_proxy_score_declined] + $[mm_proxy_score_verify])::float)*100 as proxy_score_prc,
($[mm_proxy_score_verify]::float/( $[mm_proxy_score_declined] + $[mm_proxy_score_verify])::float)*100 as proxy_score_verify_prc,
(($[mm_proxy_score_approved] + $[mm_proxy_score_declined] + $[mm_proxy_score_verify])::float/15764)*100 as mm_proxy_score_coverage,
-- 
-- (($[mm_anonymous_proxy_declined] + $[mm_anonymous_proxy_verify])::float/($[mm_anonymous_proxy_approved] + $[mm_anonymous_proxy_declined] + $[mm_anonymous_proxy_verify])::float)*100 as anonymous_proxy_prc,
-- ($[mm_anonymous_proxy_verify]::float/( $[mm_anonymous_proxy_declined] + $[mm_anonymous_proxy_verify])::float)*100 as anonymous_proxy_verify_prc,

(($[blocked_declined] + $[blocked_verify])::float/($[blocked_approved] + $[blocked_declined] + $[blocked_verify])::float)*100 as blocked_prc,
($[blocked_verify]::float/( $[blocked_declined] + $[blocked_verify])::float)*100 as blocked_verify_prc,
(($[blocked_approved] + $[blocked_declined] + $[blocked_verify])::float/15928)*100 as blocked_coverage,

(($[radar_declined]+$[radar_verify])::float/($[radar_approved] + $[radar_declined] + $[radar_verify])::float)*100 as radar_prc,
($[radar_verify]::float/($[radar_declined] + $[radar_verify])::float)*100 as radar_verify_prc,
(($[radar_approved] + $[radar_declined] +  $[radar_verify])::float/14771)*100 as radar_coverage,

(($[corporate_declined] + $[corporate_verify])::float/($[corporate_approved] + $[corporate_declined] + $[corporate_verify])::float)*100 as corporate_prc,
( $[corporate_verify]::float/($[corporate_declined] + $[corporate_verify])::float)*100 as corporate_verify_prc,

(($[riskscore_declined] + $[riskscore_verify])::float/($[riskscore_approved] + $[riskscore_declined] + $[riskscore_verify])::float)*100 as riskscore_prc,
($[riskscore_verify]::float/($[riskscore_declined] + $[riskscore_verify])::float)*100 as riskscore_verify_prc,
(($[riskscore_approved] + $[riskscore_declined] + $[riskscore_verify])::float/15309)*100 as riskscore_coverage;

--@WbResult query_results
$[my_query];






