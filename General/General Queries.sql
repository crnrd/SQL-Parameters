-----------------------------------------------------------------------------------------------
-- update to desired payment id and run
-----------------------------------------------------------------------------------------------
WbVarDef pid = '$[?id]';

--@WbResult user authorization requests
select payment_id,created_at, tx_type,
request_data->>'amount' amount,
status,
request_data->>'address1' address1,
request_data->>'address2' address2,
request_data->>'city' city,
request_data->>'zipcode' zipcode,
request_data->>'state' state,
request_data->>'country' country,
raw_response->>'billingfirstname' first_name_on_card,
raw_response->>'billinglastname' last_name_on_card,
raw_response->>'maskedpan' card_number, 
raw_response->>'expirydate' expiration_date,
raw_response->>'eci' eci, 
raw_response->>'issuer' issuer,
raw_response->>'enrolled' card_3ds_enrolled,
raw_response->>'status' card_3ds_status, 
case
when raw_response ->> 'securityresponseaddress' = '2' then 'Matched'
when raw_response ->> 'securityresponseaddress' = '4' then 'Not Matched'
when raw_response ->> 'securityresponseaddress' = '1' then 'Not Checked'
when raw_response ->> 'securityresponseaddress' = '0' then 'Not Given'
else null end address_avs,
case
when raw_response ->> 'securityresponsepostcode' = '2' then 'Matched'
when raw_response ->> 'securityresponsepostcode' = '4' then 'Not Matched'
when raw_response ->> 'securityresponsepostcode' = '1' then 'Not Checked'
when raw_response ->> 'securityresponsepostcode' = '0' then 'Not Given'
else null end postcode_avs,
raw_response->>'acquirerresponsemessage' issuer_response,
request_data->>'email' email,
request_data->>'phone' phone, 
request_data->>'currency' currency,
raw_response->>'paymenttypedescription' card_type
from proc_requests where payment_id in (select id from payments where partner_end_user_id = (select partner_end_user_id from payments where id= $[pid]) or simplex_end_user_id = (select simplex_end_user_id from payments where id= $[pid]))
and tx_type = 'authorization'
order by created_at asc;


--@WbResult all users CCs
select distinct credit_card from payments_log where current_payment_id in (select py.id from payments py where py.partner_end_user_id in (select peu.id from partner_end_users peu where email in (select (validation_request_body ->> 'email') from payments where id =($[pid]))));


--@WbResult payments
select py.id, py.status, py.created_at, py.pay_to_partner_id, py.partner_end_user_id, py.order_id order_id, py.credit_card, total_amount, py.currency, py.handling_user_id
from payments py
where py.id in (select py.id from payments py where py.partner_end_user_id in (select peu.id from partner_end_users peu where email in (select (validation_request_body ->> 'email') from payments where id =($[pid]))))
order by py.id;



--@WbResult user form changes
select payment_id, ube.inserted_at,
request_data->>'first_name' first_name,
request_data->>'last_name'last_name,
request_data->>'phone' phone,
oc.data->>'name' as phone_name,
request_data->>'address' address1,
request_data->>'address2' address2,
request_data->>'city' city,
request_data->>'state' state,
request_data->>'zip' zip,
request_data->>'country' country,
request_data->>'total_amount' amount,
request_data->>'currency' currency,
request_data->>'comment' user_comment
from user_browser_events ube left join enrich_opencnam oc on oc.phone ilike request_data->>'phone'  where payment_id in (select id from payments where partner_end_user_id = (select partner_end_user_id from payments where id = $[pid]) or simplex_end_user_id = (select simplex_end_user_id from payments where id = $[pid]))

and  event_type = 'validate' order by ube.id asc;


--@WbResult decisions on user
-----------------------------------------------------------------------
SELECT distinct p.id,
       p.status,
       p.created_at,
       p.credit_card,
       p.country, p.total_amount, p.currency,
       seu.first_name|| seu.last_name user_name, 
       p.first_name_card || p.last_name_card name_on_card,       
       seu.phone,
       peu.email,
       ps.full_name partner_name, p.handling_at, u.email handling_user,
       d.application_name,d.decision, d.reason
FROM proc_requests pr
  LEFT JOIN payments p ON pr.payment_id = p.id
  LEFT JOIN partner_end_users peu ON p.partner_end_user_id = peu.id
  LEFT JOIN simplex_end_users seu ON p.simplex_end_user_id = seu.id
  LEFT JOIN partners ps ON peu.partner_id = ps.id
  LEFT JOIN decisions d on d.payment_id = p.id
  LEFT JOIN users u on p.handling_user_id = u.id and d.application_name='Manual'
WHERE p.partner_end_user_id = (select partner_end_user_id from payments where id = $[pid]) or p.simplex_end_user_id = (select simplex_end_user_id from payments where id = $[pid])
ORDER BY p.id asc; 


--@WbResult all user browser events
select payment_id, event_type, inserted_at,
request_data->>'first_name',
request_data->>'last_name',
request_data->>'phone' phone,
request_data->>'address' address1,
request_data->>'address2' address2,
request_data->>'city' city,
request_data->>'state' state,
request_data->>'zip' zip,
request_data->>'country' country,
request_data->>'total_amount' amount,
request_data->>'currency' currency,
request_data->>'comment' user_comment,
response_data,
api_requests
from user_browser_events where payment_id in (select id from payments where partner_end_user_id = (select partner_end_user_id from payments where id = $[pid]) or simplex_end_user_id = (select simplex_end_user_id from payments where id = $[pid]))
order by id asc;


--@WbResult all user proc_requests
select payment_id,created_at, tx_type,
request_data->>'amount' amount,
status,
request_data->>'address1' address1,
request_data->>'address2' address2,
request_data->>'city' city, 
request_data->>'zipcode' zipcode,
request_data->>'state' state,
request_data->>'country' country,
raw_response->>'billingfirstname' first_name_on_card,
raw_response->>'billinglastname' last_name_on_card,
raw_response->>'maskedpan' card_number, 
raw_response->>'expirydate' expiration_date,
raw_response->>'eci' eci, 
raw_response->>'issuer' issuer,
raw_response->>'enrolled' card_3ds_enrolled,
raw_response->>'status' card_3ds_status, 
case 
when raw_response ->> 'securityresponseaddress' = '2' then 'Matched'
when raw_response ->> 'securityresponseaddress' = '4' then 'Not Matched'
when raw_response ->> 'securityresponseaddress' = '1' then 'Not Checked'
when raw_response ->> 'securityresponseaddress' = '0' then 'Not Given'
else null end address_avs,
case
when raw_response ->> 'securityresponsepostcode' = '2' then 'Matched'
when raw_response ->> 'securityresponsepostcode' = '4' then 'Not Matched'
when raw_response ->> 'securityresponsepostcode' = '1' then 'Not Checked'
when raw_response ->> 'securityresponsepostcode' = '0' then 'Not Given'
else null end postcode_avs,
raw_response->>'acquirerresponsemessage' issuer_response,
request_data->>'email' email,
request_data->>'phone' phone, 
request_data->>'currency' currency,
raw_response->>'paymenttypedescription' card_type
from proc_requests where payment_id in (select id from payments where partner_end_user_id = (select partner_end_user_id from payments where id= $[pid]) or simplex_end_user_id = (select simplex_end_user_id from payments where id= $[pid]))
--and tx_type = 'authorization'
order by created_at asc;