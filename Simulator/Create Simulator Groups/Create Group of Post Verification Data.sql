-- ALL RELEVANT PAYMENTS WITH NEW PROCESSOR (a lot... - use limit...)
INSERT INTO simulator_groups
(
  description
)
VALUES
(
  '$[?description]'
);

WbVarDef group_id=@"SELECT MAX(id) FROM simulator_groups";

WITH p as (select picture_data.payment_id, u.inserted_at 
from 
(select payment_id, upload_id from selfie_kyc_exif 
union  select payment_id,upload_id from google_vision_selfies_results
union  select payment_id,upload_id from ghiro) picture_data 
left join uploads u on picture_data.upload_id = u.id
              )

INSERT INTO simulator_parameters
( group_id,
  payment_id,
  time_point,
  risk_mode
)
SELECT ($[group_id],
       payment_id, inserted_at as pit, 'conservative'
FROM p;
COMMIT;


-- checking your group
select   max(group_id) from simulator_groups;     
