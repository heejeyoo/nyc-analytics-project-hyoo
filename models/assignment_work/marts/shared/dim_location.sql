-- Location dimension shared by both restaurant applications and 311 service reqs

WITH all_locations AS (
   -- Get locations from 311 requests
   SELECT DISTINCT
        borough --TODO replace (HINT: look @ dimensional model & staging data!)
        -- Location - clean zip code, handling several common zip code data problems
        CASE
            WHEN UPPER(TRIM(CAST(incident_zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN UPPER(TRIM(CAST(incident_zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
            WHEN LENGTH(CAST(incident_zip AS STRING)) = 5 THEN CAST(incident_zip AS STRING)
            WHEN LENGTH(CAST(incident_zip AS STRING)) = 9 THEN CAST(incident_zip AS STRING)
            WHEN LENGTH(CAST(incident_zip AS STRING)) = 10
                AND REGEXP_CONTAINS(CAST(incident_zip AS STRING), r'^\d{5}-\d{4}')
            THEN CAST(incident_zip AS STRING)
            ELSE NULL
        END AS zip_code
   FROM {{ ref('stg_nyc_311_dot') }}
   WHERE borough IS NOT NULL

   UNION DISTINCT

   -- Get locations from restaurant applications
   SELECT DISTINCT
       borough -- TODO replace (HINT: look @ dimensional model & staging data!)
       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(zip AS STRING)
           ELSE NULL
       END AS zip_code,
   FROM {{ ref('stg_nyc_open_restaurant_apps') }}
   WHERE borough IS NOT NULL
),

location_dimension AS (
   SELECT
       {{ dbt_utils.generate_surrogate_key(['borough', 'zip_code']) }} AS location_key,
       borough,
       zip_code
   FROM all_locations
)

SELECT * FROM location_dimension --TODO replace ??s with what to select. HINT: May be quite simple!

