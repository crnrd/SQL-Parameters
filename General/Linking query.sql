--The all-famous linking query
-----------------------------------------------------------------------------------------------
-- insert payment ID
-- lists of all relevant ccs, phones are created
-- first table will be the number of users who used this element (for instance - how many users used this cookie/phone/etc)
-- the next one will show the details (the email of the user who used each element and payment ID)
-- phones will appear in a similar way in the next result
-- finally you have credit cards- here you can check the experation date.
-----------------------------------------------------------------------------------------------
-- 78570	
-- 1. enter payment_id
-----------------------------------------------------------------------------------------------
-- ($[pid])
WbVarDef pid = $[?pid]; 
-----------------------------------------------------------------------------------------------
-- 2. variables and lists creation
-----------------------------------------------------------------------------------------------

WbVarDef seu_id = "select simplex_end_user_id from payments where id = $[pid]"; 

WbVarDef peu_id = "select id from partner_end_users where email ilike (select email from simplex_end_users where id = ($[seu_id]))"; 

WbVarDef payments_ids = "select distinct id from payments where simplex_end_user_id = ($[seu_id]) or partner_end_user_id in ($[peu_id])"; 

WbVarDef btc_addresses = "select distinct btc_address from payments where simplex_end_user_id = ($[seu_id]) or partner_end_user_id in ($[peu_id]) and btc_address <> '' and btc_address is not null "; 

WbVarDef cookies = "select distinct simplex_login->>'uaid' from payments where simplex_end_user_id = ($[seu_id]) or partner_end_user_id in ($[peu_id]) and simplex_login->>'uaid' <> ''"; 

WbVarDef phones = "select phone from phone_verifications where partner_end_user_id in ($[peu_id])
OR partner_end_user_id in (select distinct partner_end_user_id from payments where simplex_end_user_id = ($[seu_id])) and phone != ''
UNION
select phone from partner_end_users_log where current_end_user_id in ($[peu_id]) and phone != ''
UNION
select phone from simplex_end_users_log where current_simplex_user_id = ($[seu_id]) and phone != '' 
UNION
select phone from partner_end_users where id in ($[peu_id]) and phone != ''
UNION
select phone from simplex_end_users where id = ($[seu_id]) and phone != '' ";

WbVarDef ccs = "
select credit_card from payments where simplex_end_user_id = ($[seu_id]) and credit_card !=''
UNION
select credit_card from payments where partner_end_user_id in ($[peu_id]) and credit_card !=''
UNION
select validation_request_body #>> '{credit_card}' from payments where simplex_end_user_id = ($[seu_id]) and validation_request_body #>> '{credit_card}' !=''
UNION
select validation_request_body #>> '{credit_card}' from payments where partner_end_user_id in ($[peu_id]) and validation_request_body #>> '{credit_card}' !=''
UNION
select credit_card from payments_log where simplex_end_user_id = ($[seu_id]) and credit_card !=''
UNION
select credit_card from payments_log where partner_end_user_id in ($[peu_id]) and credit_card !=''
UNION
select validation_request_body #>> '{credit_card}' from payments_log where simplex_end_user_id = ($[seu_id]) and validation_request_body #>> '{credit_card}' !=''
UNION
select validation_request_body #>> '{credit_card}' from payments_log where partner_end_user_id in ($[peu_id]) and validation_request_body #>> '{credit_card}' !=''
UNION
select masked_credit_card from proc_requests where masked_credit_card != '' and masked_credit_card is not null
and (payment_id in (select id from payments where partner_end_user_id in ($[peu_id]))
or payment_id in (select id from payments where simplex_end_user_id = ($[seu_id])))
";
-----------------------------------------------------------------------------------------------
-- 3. tables creation
-----------------------------------------------------------------------------------------------
--@WbResult Number of linked elements 
-- element , number of emails who used it
select element_type, count(distinct(email)) as num_users from (
-- cookie
select peu.email, 'cookie' element_type  from payments p
left join partner_end_users peu on p.partner_end_user_id = peu.id
where (simplex_login->> 'uaid') in ($[cookies]) 
and (simplex_login->> 'uaid') != ''
UNION ALL
--ip
select peu.email, 'ip' element_type  from payments p
left join partner_end_users peu on p.partner_end_user_id = peu.id
where ((simplex_login->> 'ip') = (select (simplex_login->> 'ip') from payments where id = $[pid])  
or (partner_login->> 'ip') = (select (simplex_login->> 'ip') from payments where id = $[pid]))
and (select (simplex_login->> 'ip') from payments where id = $[pid]) != ''
UNION ALL
select peu.email, 'ip' element_type  from payments_log pl
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where ((partner_login->> 'ip') = (select (simplex_login->> 'ip') from payments where id = $[pid])  ) 
and (select (simplex_login->> 'ip') from payments where id = $[pid])   != '' 
UNION ALL
-- btc_address         
select peu.email, 'btc_address' element_type  from payments p
left join partner_end_users peu on p.partner_end_user_id = peu.id
where p.btc_address in ($[btc_addresses]) and p.btc_address != ''
UNION ALL
select peu.email, 'btc_address' element_type  from payments_log pl
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where pl.btc_address in ($[btc_addresses]) and  pl.btc_address != ''
UNION ALL
--address
select peu.email, 'address' element_type from payments p 
left join partner_end_users peu on p.partner_end_user_id = peu.id
where lower(p.address1 || ' ' || p.address2 || ' ' || p.city || ' ' || p.state || ' ' || p.country || ' ' || p.zipcode) = (select lower(address1 || ' ' || address2 || ' ' || city || ' ' || state || ' ' || country || ' ' || zipcode) from payments where id = $[pid])  
UNION ALL
-- ccs
select peu.email, 'masked CC number' element_type from payments p 
left join partner_end_users peu on p.partner_end_user_id = peu.id
where p.credit_card in ($[ccs])  
UNION ALL 
select peu.email, 'masked CC number' element_type from payments p 
left join partner_end_users peu on p.partner_end_user_id = peu.id
where p.validation_request_body #>> '{credit_card}' in ($[ccs])  
UNION ALL 
select peu.email, 'masked CC number' element_type from payments_log pl 
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where pl.credit_card in ($[ccs])  
UNION ALL 
select peu.email, 'masked CC number' element_type from payments_log pl 
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where pl.validation_request_body #>> '{credit_card}' in ($[ccs])  
UNION ALL 
select peu.email,'masked CC number' element_type from proc_requests pr
left join payments p on p.id = pr.payment_id
left join partner_end_users peu on p.partner_end_user_id = peu.id
where pr.masked_credit_card in ($[ccs])
UNION ALL
-- phones
select peu.email, pv.phone from phone_verifications pv
left join partner_end_users peu on pv.partner_end_user_id = peu.id
where pv.phone in ($[phones]) 
union all
select email,phone from partner_end_users_log 
where phone in ($[phones]) 
union all
select email,phone from partner_end_users 
where phone in ($[phones]) 
union all
select email,phone from simplex_end_users_log
where phone in ($[phones])
union all
select email,phone from simplex_end_users
where phone in ($[phones])
)a group by 1
order by num_users desc;

-----------------------------------------------------------------------------------------------                     
--@WbResult Detailed Results 
-- ip, cookie, btc_address - automation links through payments and payments_log tables, and through both simplex_login and partner_login
-- address - red asterisk shown next to address in DSS comes from DEV. adrress fields include address1, address2, city, state, country, zipcode
-- automation does not use address for linking
-- cookie
select peu.email, max(p.id)  as last_payment ,count(distinct p.id) as number_of_payments_it_was_used, 'cookie' element_type  from payments p
left join partner_end_users peu on p.partner_end_user_id = peu.id
where (simplex_login->> 'uaid') in ($[cookies]) 
and (simplex_login->> 'uaid') != ''
group by 1
UNION ALL
--ip
select peu.email, max(p.id)  as last_payment ,count(distinct p.id) as number_of_payments_it_was_used, 'ip' element_type  from payments p
left join partner_end_users peu on p.partner_end_user_id = peu.id
where ((simplex_login->> 'ip') = (select (simplex_login->> 'ip') from payments where id = $[pid])  
or (partner_login->> 'ip') = (select (simplex_login->> 'ip') from payments where id = $[pid]))
and (select (simplex_login->> 'ip') from payments where id = $[pid]) != ''
group by 1
UNION ALL
select peu.email, max(pl.current_payment_id)  as last_payment ,  count(distinct pl.current_payment_id) as number_of_payments_it_was_used, 'ip' element_type  from payments_log pl
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where ((partner_login->> 'ip') = (select (simplex_login->> 'ip') from payments where id = $[pid])  ) 
and (select (simplex_login->> 'ip') from payments where id = $[pid])   != ''
group by 1
UNION ALL
-- btc_address         
select peu.email,max(p.id)  as last_payment ,count(distinct p.id) as number_of_payments_it_was_used, 'btc_address' element_type  from payments p
left join partner_end_users peu on p.partner_end_user_id = peu.id
where p.btc_address in  ($[btc_addresses])  and p.btc_address != ''
group by 1
UNION ALL
select peu.email,max(pl.current_payment_id)  as last_payment, count(distinct pl.current_payment_id) as number_of_payments_it_was_used, 'btc_address' element_type  from payments_log pl
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where pl.btc_address  in  ($[btc_addresses]) and pl.btc_address != ''
group by 1
UNION ALL


-- -- ccs
select distinct email,last_payment,number_of_payments_it_was_used,element_type from (
select peu.email, max(p.id)  as last_payment, count(distinct p.id) as number_of_payments_it_was_used, 'masked CC number' element_type from payments p 
left join partner_end_users peu on p.partner_end_user_id = peu.id
where p.credit_card in ($[ccs])  
group by 1
UNION ALL 
select peu.email, max(p.id)  as last_payment, count(distinct p.id) as number_of_payments_it_was_used, 'masked CC number' element_type from payments p 
left join partner_end_users peu on p.partner_end_user_id = peu.id
where p.validation_request_body #>> '{credit_card}' in ($[ccs])  
group by 1
UNION ALL 
select peu.email, max(pl.current_payment_id)  as last_payment, count(distinct pl.current_payment_id) as number_of_payments_it_was_used, 'masked CC number' element_type from payments_log pl 
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where pl.credit_card in ($[ccs])  
group by 1
UNION ALL 
select peu.email, max(pl.current_payment_id)  as last_payment, count(distinct pl.current_payment_id) as number_of_payments_it_was_used, 'masked CC number' element_type from payments_log pl 
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where pl.validation_request_body #>> '{credit_card}' in ($[ccs])  
group by 1
UNION ALL 
select peu.email, max(pr.payment_id) as last_payment, count(distinct pr.payment_id) as number_of_payments_it_was_used, 'masked CC number' element_type from proc_requests pr
left join payments p on p.id = pr.payment_id
left join partner_end_users peu on p.partner_end_user_id = peu.id
where pr.masked_credit_card in ($[ccs])  
group by 1 )a
order by element_type, email;
-----------------------------------------------------------------------------------------------        
-----------------------------------------------------------------------------------------------                       
--@WbResult Linked emails and phones
 select distinct phone, email from (select pver.phone,   peu.email as email from phone_verifications pver
                       left join partner_end_users peu on pver.partner_end_user_id = peu.id
                       where pver.phone in ($[phones]) and pver.inserted_at < now()
                       union all
                       select  phone, email as email from partner_end_users_log peu_log
                       where phone in ($[phones]) and created_at < now()
                       union all
                       select  peu.phone, peu.email as email from partner_end_users peu
                       where peu.phone in ($[phones]) and peu.created_at < now()
                       union all
                       select  phone, email as email from simplex_end_users_log
                       where phone in ($[phones]) and created_at < now()
                       union all
                       select  phone,  email as email from simplex_end_users
                       where phone in ($[phones]) and created_at < now()) a
                       order by phone, email;
-----------------------------------------------------------------------------------------------                          
-----------------------------------------------------------------------------------------------                       
--@WbResult All Linked Credit Cards
select distinct email,payment_id,partner_end_user_id,credit_card, case when status = 0 and payment_id in (select id from payments where created_at < (NOW() -INTERVAL '6 hours')) then 20 else status end status 



,card_expiry_year,card_expiry_month from (
select peu.email, p.id as payment_id, partner_end_user_id, credit_card, status, card_expiry_year, card_expiry_month from payments p 
left join partner_end_users peu on p.partner_end_user_id = peu.id
where p.credit_card in ($[ccs])  
UNION ALL 
select peu.email, p.id as payment_id, partner_end_user_id, credit_card, status, card_expiry_year, card_expiry_month from payments p 
left join partner_end_users peu on p.partner_end_user_id = peu.id
where p.validation_request_body #>> '{credit_card}' in ($[ccs])  
UNION ALL 
select peu.email, pl.current_payment_id as payment_id, partner_end_user_id, credit_card, status, card_expiry_year, card_expiry_month from payments_log pl
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where pl.credit_card in ($[ccs])    
UNION ALL 
select peu.email, pl.current_payment_id as payment_id, partner_end_user_id, credit_card, status, card_expiry_year, card_expiry_month from payments_log pl
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where pl.validation_request_body #>> '{credit_card}' in ($[ccs]) 
UNION ALL 
select peu.email, pr.payment_id, peu.id, pr.masked_credit_card credit_card, p.status, cast(split_part(raw_response->>'expirydate','/',2) as int) card_expiry_year, cast(split_part(raw_response->>'expirydate','/',1) as int) card_expiry_month from proc_requests pr
left join payments p on p.id = pr.payment_id
left join partner_end_users peu on p.partner_end_user_id = peu.id
where pr.masked_credit_card in ($[ccs]) ) a order by credit_card, email;
------------------------------------------------------------------------------------------------------------------------------------------------

-- @WbResult all linked emails, payments and their status
select b.email, p.id, p.status, p.chargeback_at from (
select distinct email from (
select peu.email, max(p.id)  as last_payment ,count(distinct p.id) as number_of_payments_it_was_used, 'cookie' element_type  from payments p
left join partner_end_users peu on p.partner_end_user_id = peu.id
where (simplex_login->> 'uaid') in ($[cookies]) 
and (simplex_login->> 'uaid') != ''
group by 1
UNION ALL
--ip
select peu.email, max(p.id)  as last_payment ,count(distinct p.id)  as number_of_payments_it_was_used, 'ip' element_type  from payments p
left join partner_end_users peu on p.partner_end_user_id = peu.id
where ((simplex_login->> 'ip') = (select (simplex_login->> 'ip') from payments where id = $[pid])  
or (partner_login->> 'ip') = (select (simplex_login->> 'ip') from payments where id = $[pid]))
and (select (simplex_login->> 'ip') from payments where id = $[pid]) != ''
group by 1
UNION ALL
select peu.email, max(pl.current_payment_id)  as last_payment ,  count(distinct pl.current_payment_id) as number_of_payments_it_was_used, 'ip' element_type  from payments_log pl
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where ((partner_login->> 'ip') = (select (simplex_login->> 'ip') from payments where id = $[pid])  ) 
and (select (simplex_login->> 'ip') from payments where id = $[pid])   != ''
group by 1
UNION ALL
-- btc_address         
select peu.email,max(p.id)  as last_payment ,count(distinct p.id) as number_of_payments_it_was_used, 'btc_address' element_type  from payments p
left join partner_end_users peu on p.partner_end_user_id = peu.id
where p.btc_address in  ($[btc_addresses])  and p.btc_address != ''
group by 1
UNION ALL
select peu.email,max(pl.current_payment_id)  as last_payment, count(distinct pl.current_payment_id) as number_of_payments_it_was_used, 'btc_address' element_type  from payments_log pl
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where pl.btc_address  in  ($[btc_addresses]) and pl.btc_address != ''
group by 1
UNION ALL

-- -- ccs
select distinct email,last_payment,number_of_payments_it_was_used,element_type from (
select peu.email, max(p.id)  as last_payment, count(distinct p.id) as number_of_payments_it_was_used, 'masked CC number' element_type from payments p 
left join partner_end_users peu on p.partner_end_user_id = peu.id
where p.credit_card in ($[ccs])  
group by 1
UNION ALL 
select peu.email, max(p.id)  as last_payment, count(distinct p.id) as number_of_payments_it_was_used, 'masked CC number' element_type from payments p 
left join partner_end_users peu on p.partner_end_user_id = peu.id
where p.validation_request_body #>> '{credit_card}' in ($[ccs])  
group by 1
UNION ALL 
select peu.email, max(pl.current_payment_id)  as last_payment, count(distinct pl.current_payment_id) as number_of_payments_it_was_used, 'masked CC number' element_type from payments_log pl 
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where pl.credit_card in ($[ccs])  
group by 1
UNION ALL 
select peu.email, max(pl.current_payment_id)  as last_payment, count(distinct pl.current_payment_id) as number_of_payments_it_was_used, 'masked CC number' element_type from payments_log pl 
left join partner_end_users peu on pl.partner_end_user_id = peu.id
where pl.validation_request_body #>> '{credit_card}' in ($[ccs])  
group by 1
UNION ALL 
select peu.email, max(pr.payment_id) as last_payment, count(distinct pr.payment_id) as number_of_payments_it_was_used, 'masked CC number' element_type from proc_requests pr
left join payments p on p.id = pr.payment_id
left join partner_end_users peu on p.partner_end_user_id = peu.id
where pr.masked_credit_card in ($[ccs])  
group by 1 )a
order by element_type, email) b) b
join payments p
on p.validation_request_body->>'email' = b.email
;
-----------------------------------------------------------------------------------------------                          

--@WbResult All emails used by THIS user

SELECT DISTINCT email
FROM partner_end_users_log
WHERE current_end_user_id IN (SELECT partner_end_user_id
                              FROM payments
                              WHERE validation_request_body ->> 'email' ilike (SELECT validation_request_body ->> 'email'
                                                                               FROM payments
                                                                               WHERE id = $[pid]))
                                                                               
OR
current_end_user_id IN (SELECT partner_end_user_id
                              FROM payments
                              WHERE simplex_end_user_id in (SELECT simplex_end_user_id
                                                                               FROM payments
                                                                               WHERE id = $[pid]))
                                                                           
OR
current_end_user_id IN (SELECT partner_end_user_id
                              FROM payments
                              WHERE partner_end_user_id in (SELECT partner_end_user_id
                                                                               FROM payments
                                                                               WHERE id = $[pid]))
;