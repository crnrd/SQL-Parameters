--@WbResult pay_by_bin
with pr as 
(select payment_id from proc_requests where substring(masked_credit_card from 1 for 6) 
in (select substring(credit_card from 1 for 6) from payments where id in (:p_ids))
and created_at between ((select created_at from payments where id = :p_ids) - interval '21 days' )
and (select created_at from payments where id = :p_ids))
select distinct on (py.id) py.id, py.status, py.credit_card, (py.simplex_login ->> 'ip') as ip, py.created_at, py.handling_at, u.email as handler, total_amount, py.currency, 
      py.email, ea.ea_advice, ea.ea_age ea_reason, py.first_name, py.last_name, py.first_name_card, py.last_name_card, py.country, py.state, py.city, py.address1, py.zipcode, cbks.cbktype, rrqs.rrqcode, frws.frwt
from payments py
left join (select peu.id, p.name from partner_end_users peu left join partners p on p.id = peu.partner_id) nm on nm.id = py.partner_end_user_id 
left join users u on u.id = py.handling_user_id
left join (select email, data #>> '{query,results,0,EAAdvice}' EA_advice, data #>> '{query,results,0,EAReason}' EA_age from enrich_email_age) ea on ea.email = py.email
Left join
    (select distinct cbk.payment_id cbkid, cbkt.chargeback_type cbktype from chargebacks cbk
     left join chargeback_types cbkt on cbkt.reason_code = cbk.reason_code) cbks on cbks.cbkid = py.id
Left join 
    (select rrq.payment_id rrqid, rrq.reason_code rrqcode from retrieval_requests rrq) rrqs on rrqs.rrqid = py.id
left join
     (select frw.payment_id frwid, frw.processor frwt from fraud_warnings frw) frws on frws.frwid = py.id
where py.id in (select payment_id from pr)
order by 1
;
--@WbResult pay_by_ip3
with p as (select id from payments where 
substring((simplex_login ->> 'ip') from '[0-9]+.[0-9]+.[0-9]+') in (select substring((simplex_login ->> 'ip') from '[0-9]+.[0-9]+.[0-9]+') from payments where id IN (:p_ids))
and created_at between ((select created_at from payments where id = :p_ids) - interval '21 days') 
and (select created_at from payments where id = :p_ids))
select distinct on (py.id) py.id, py.status, py.credit_card, (py.simplex_login ->> 'ip') as ip, py.created_at, py.handling_at, u.email as handler, total_amount, py.currency, 
      py.email, ea.ea_advice, ea.ea_age ea_reason, py.first_name, py.last_name, py.first_name_card, py.last_name_card, py.country, py.state, py.city, py.address1, py.zipcode, cbks.cbktype, rrqs.rrqcode, frws.frwt
from payments py
left join (select peu.id, p.name from partner_end_users peu left join partners p on p.id = peu.partner_id) nm on nm.id = py.partner_end_user_id 
left join users u on u.id = py.handling_user_id
left join (select email, data #>> '{query,results,0,EAAdvice}' EA_advice, data #>> '{query,results,0,EAReason}' EA_age from enrich_email_age) ea on ea.email = py.email
Left join
    (select distinct cbk.payment_id cbkid, cbkt.chargeback_type cbktype from chargebacks cbk
     left join chargeback_types cbkt on cbkt.reason_code = cbk.reason_code) cbks on cbks.cbkid = py.id
Left join 
    (select rrq.payment_id rrqid, rrq.reason_code rrqcode from retrieval_requests rrq) rrqs on rrqs.rrqid = py.id
left join
     (select frw.payment_id frwid, frw.processor frwt from fraud_warnings frw) frws on frws.frwid = py.id
where py.id in (select id from p) 
;
--@WbResult pay_by_domain
with p as (select id from payments where 
split_part(email, '@', 2) in (select split_part(email, '@', 2) from payments where id  in (:p_ids))
and created_at between ((select created_at from payments where id = :p_ids) - interval '21 days')
and (select created_at from payments where id = :p_ids))
select distinct on (py.id) py.id, py.status, py.credit_card, (py.simplex_login ->> 'ip') as ip, py.created_at, py.handling_at, u.email as handler, total_amount, py.currency, 
      py.email, ea.ea_advice, ea.ea_age ea_reason, py.first_name, py.last_name, py.first_name_card, py.last_name_card, py.country, py.state, py.city, py.address1, py.zipcode, cbks.cbktype, rrqs.rrqcode, frws.frwt
from payments py
left join (select peu.id, p.name from partner_end_users peu left join partners p on p.id = peu.partner_id) nm on nm.id = py.partner_end_user_id 
left join users u on u.id = py.handling_user_id
left join (select email, data #>> '{query,results,0,EAAdvice}' EA_advice, data #>> '{query,results,0,EAReason}' EA_age from enrich_email_age) ea on ea.email = py.email
Left join
    (select distinct cbk.payment_id cbkid, cbkt.chargeback_type cbktype from chargebacks cbk
     left join chargeback_types cbkt on cbkt.reason_code = cbk.reason_code) cbks on cbks.cbkid = py.id
Left join 
    (select rrq.payment_id rrqid, rrq.reason_code rrqcode from retrieval_requests rrq) rrqs on rrqs.rrqid = py.id
left join
     (select frw.payment_id frwid, frw.processor frwt from fraud_warnings frw) frws on frws.frwid = py.id
where py.id in (select id from p) ;



--@WbResult pay_by_ip_bin
with p as (
select distinct payment_id, ip_country, bin_country from (
select  p.id as payment_id, p.created_at, 
(em.data ->> 'countryCode') as ip_country, 

eb.bin, (eb.response_data #>> '{country, alpha2}') as bin_country from 
payments p
 join enrich_binlist eb on eb.bin = substring(p.credit_card from 1 for 6) 
 join enrich_maxmind em on (em.request_data ->> 'i') = p.simplex_login ->> 'ip'
where credit_card is not null

)a
where ip_country in (select data ->> 'countryCode' from enrich_maxmind where (request_data ->> 'i') in (select (p.simplex_login ->> 'ip') from payments p where id in (:p_ids))) 
and bin_country in (select response_data #>> '{country, alpha2}' from enrich_binlist where bin in (select substring(p.credit_card from 1 for 6) from payments p where id in (:p_ids))) 
and created_at between ((select created_at from payments where id = :p_ids) - interval '21 days')
and (select created_at from payments where id = :p_ids)
group by 1,2,3)

select distinct on (py.id) py.id, py.status, py.credit_card, (py.simplex_login ->> 'ip') as ip, py.created_at, py.handling_at, u.email as handler, total_amount, py.currency, 
      py.email, ea.ea_advice, ea.ea_age ea_reason, py.first_name, py.last_name,
       py.first_name_card, py.last_name_card, py.country, py.state, py.city, py.address1, py.zipcode, cbks.cbktype, rrqs.rrqcode, frws.frwt,
       p.ip_country, p.bin_country
       
from payments py
left join (select peu.id, p.name from partner_end_users peu left join partners p on p.id = peu.partner_id) nm on nm.id = py.partner_end_user_id 
left join users u on u.id = py.handling_user_id
left join (select email, data #>> '{query,results,0,EAAdvice}' EA_advice, data #>> '{query,results,0,EAReason}' EA_age from enrich_email_age) ea on ea.email = py.email
Left join
    (select distinct cbk.payment_id cbkid, cbkt.chargeback_type cbktype from chargebacks cbk
     left join chargeback_types cbkt on cbkt.reason_code = cbk.reason_code) cbks on cbks.cbkid = py.id
Left join 
    (select rrq.payment_id rrqid, rrq.reason_code rrqcode from retrieval_requests rrq) rrqs on rrqs.rrqid = py.id
left join
     (select frw.payment_id frwid, frw.processor frwt from fraud_warnings frw) frws on frws.frwid = py.id
join p on py.id = p.payment_id


