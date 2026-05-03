-- Clean and standardize NYC Restaurant Open Seating application data
-- One row per application

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           objectid,
           time_of_submission,
           restaurant_name,
           legal_business_name,
           doing_business_as_dba,
           bulding_number,
           borough,
           zip,
           business_address,
           food_service_establishment,
           latitude,
           longitude,
           seating_interest_sidewalk,
           approved_for_sidewalk_seating,
           approved_for_roadway_seating,
           sidewalk_dimensions_length,
           sidewalk_dimensions_width,
           sidewalk_dimensions_area,
           roadway_dimensions_length,
           roadway_dimensions_width,
           roadway_dimensions_area,
           qualify_alcohol,
           sla_serial_number,
           sla_license_type,
           landmark_district_or_building,
           landmarkdistrict_terms,
           healthcompliance_terms,
           community_board,
           council_district,
           census_tract,
           bin,
           bbl,
           nta
       ),

       -- Identifiers
       CAST(objectid AS STRING) AS application_id,

       -- Date/Time
       CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,

       -- Request details
       CAST(restaurant_name AS STRING) AS restaurant_name,
       CAST(legal_business_name AS STRING) AS legal_business_name,
       CAST(doing_business_as_dba AS STRING) AS doing_business_as,
       CAST(bulding_number AS STRING) AS building_number,
       CAST(business_address AS STRING) AS full_address,

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
       END AS zip,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

       CAST(food_service_establishment AS STRING) AS food_service_establishment_permit,
       CAST(seating_interest_sidewalk AS STRING) AS seating_interest,
       CAST(approved_for_sidewalk_seating AS STRING) AS approved_for_sidewalk_seating,
       CAST(approved_for_roadway_seating AS STRING) AS approved_for_roadway_seating,
       CAST(sidewalk_dimensions_length AS DECIMAL) AS sidewalk_dimensions_length,
       CAST(sidewalk_dimensions_width AS DECIMAL) AS sidewalk_dimensions_width,
       CAST(sidewalk_dimensions_area AS DECIMAL) AS sidewalk_dimensions_area,
       CAST(roadway_dimensions_length AS DECIMAL) AS roadway_dimensions_length,
       CAST(roadway_dimensions_width AS DECIMAL) AS roadway_dimensions_width,
       CAST(roadway_dimensions_area AS DECIMAL) AS roadway_dimensions_area,
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,
       CAST(qualify_alcohol AS STRING) AS alcohol_qualified,
       CAST(sla_serial_number AS STRING) AS sla_serial_number,
       CAST(sla_license_type AS STRING) AS sla_license_type,
       CAST(landmark_district_or_building AS STRING) AS landmark_status,
       CAST(landmarkdistrict_terms AS STRING) AS landmark_terms,
       CAST(healthcompliance_terms AS STRING) AS health_compliance_terms,
       CAST(community_board AS STRING) AS community_board,
       CAST(council_district AS STRING) AS council_district,
       CAST(census_tract AS STRING) AS census_tract,
       CAST(bin AS STRING) AS bin,
       CAST(bbl AS STRING) AS bbl,
       CAST(nta AS STRING) AS nta,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE objectid IS NOT NULL

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY objectid ORDER BY time_of_submission DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table: stg_nyc_open_restaurant_apps.sql

