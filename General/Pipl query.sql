------------------------------------------------
-- Use single quotation marks. Like that: 'alex@simplex.com'
------------------------------------------------


WbVarDef pid = '$[?email]' as email;


-- @wbResult Info

SELECT id,
email,

jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'urls'), '0'), '@name') as SM,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'urls'), '0'), 'url') as SM_link,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'names'), '0'), 'display') as name,
cast(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'images'), '0'), 'url') as varchar)  as picture,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'usernames'), '0'), 'content') as username,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'origin_countries'), '0'), 'country') as country,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'emails'), '0'), '@valid_since') as email_age,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'phones'), '0'), 'display') as phone,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'addresses'), '0') as adress
FROM enrich_pipl where email ilike ($[email])

UNION ALL 

SELECT id,
email,

jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'urls'), '1'), '@name') as SM,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'urls'), '1'), 'url') as SM_link,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'names'), '1'), 'display') as name,
cast(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'images'), '1'), 'url') as varchar)  as picture,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'usernames'), '1'), 'content') as username,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'origin_countries'), '1'), 'country') as country,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'emails'), '1'), '@valid_since') as email_age,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'phones'), '1'), 'display') as phone,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'addresses'), '1') as adress
FROM enrich_pipl where email ilike ($[email])

UNION ALL 

SELECT id,
email,

jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'urls'), '2'), '@name') as SM,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'urls'), '2'), 'url') as SM_link,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'names'), '2'), 'display') as name,
cast(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'images'), '2'), 'url') as varchar)  as picture,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'usernames'), '2'), 'content') as username,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'origin_countries'), '2'), 'country') as country,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'emails'), '2'), '@valid_since') as email_age,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'phones'), '2'), 'display') as phone,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'addresses'), '2') as adress
FROM enrich_pipl where email ilike ($[email])

UNION ALL 

SELECT id,
email,

jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'urls'), '3'), '@name') as SM,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'urls'), '3'), 'url') as SM_link,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'names'), '3'), 'display') as name,
cast(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'images'), '3'), 'url') as varchar)  as picture,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'usernames'), '3'), 'content') as username,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'origin_countries'), '3'), 'country') as country,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'emails'), '3'), '@valid_since') as email_age,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'phones'), '3'), 'display') as phone,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'addresses'), '3') as adress
FROM enrich_pipl where email ilike ($[email])

UNION ALL 

SELECT id,
email,

jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'urls'), '4'), '@name') as SM,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'urls'), '4'), 'url') as SM_link,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'names'), '4'), 'display') as name,
cast(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'images'), '4'), 'url') as varchar)  as picture,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'usernames'), '4'), 'content') as username,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'origin_countries'), '4'), 'country') as country,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'emails'), '4'), '@valid_since') as email_age,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'phones'), '4'), 'display') as phone,
jsonb_extract_path(jsonb_extract_path(jsonb_extract_path(data, 'person'), 'addresses'), '4') as adress
FROM enrich_pipl where email ilike ($[email]);


-- @wbResult tot_data

SELECT id,
email,

data ->> '@persons_count' cnt,
data -> 'available_data' ->> 'premium' as tot_info

FROM enrich_pipl where email ilike ($[email])
;