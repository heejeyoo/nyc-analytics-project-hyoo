{{ config(materialized='table') }}

WITH source AS (
    SELECT * 
    FROM {{ source('raw', 'source_nyc_311_traffic') }}
),

cleaned AS (
    SELECT
        -- Primary identifier
        CAST(unique_key AS STRING) AS request_id,

        -- Timestamps
        CAST(created_date AS TIMESTAMP) AS created_date,
        CAST(closed_date AS TIMESTAMP) AS closed_date,
        CAST(resolution_action_updated_date AS TIMESTAMP) AS resolution_action_updated_date,

        -- Agency / complaint dimensions
        UPPER(TRIM(CAST(agency AS STRING))) AS agency,
        TRIM(CAST(agency_name AS STRING)) AS agency_name,
        TRIM(CAST(complaint_type AS STRING)) AS complaint_type,
        TRIM(CAST(descriptor AS STRING)) AS descriptor,
        TRIM(CAST(descriptor_2 AS STRING)) AS descriptor_2,
        UPPER(TRIM(CAST(status AS STRING))) AS status,

        -- Location dimension candidates
        CASE
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE NULL
        END AS borough,

        CASE
            WHEN incident_zip IS NULL THEN NULL
            WHEN UPPER(TRIM(CAST(incident_zip AS STRING))) IN ('N/A', 'NA', '') THEN NULL
            WHEN REGEXP_CONTAINS(TRIM(CAST(incident_zip AS STRING)), r'^\d{5}$') THEN TRIM(CAST(incident_zip AS STRING))
            WHEN REGEXP_CONTAINS(TRIM(CAST(incident_zip AS STRING)), r'^\d{5}-\d{4}$') THEN TRIM(CAST(incident_zip AS STRING))
            ELSE NULL
        END AS incident_zip,

        TRIM(CAST(city AS STRING)) AS city,
        SAFE_CAST(council_district AS INT64) AS council_district,
        TRIM(CAST(community_board AS STRING)) AS community_board,
        TRIM(CAST(police_precinct AS STRING)) AS police_precinct,

        -- Address / geography detail
        TRIM(CAST(incident_address AS STRING)) AS incident_address,
        TRIM(CAST(street_name AS STRING)) AS street_name,
        TRIM(CAST(cross_street_1 AS STRING)) AS cross_street_1,
        TRIM(CAST(cross_street_2 AS STRING)) AS cross_street_2,
        TRIM(CAST(intersection_street_1 AS STRING)) AS intersection_street_1,
        TRIM(CAST(intersection_street_2 AS STRING)) AS intersection_street_2,
        TRIM(CAST(landmark AS STRING)) AS landmark,
        TRIM(CAST(address_type AS STRING)) AS address_type,
        TRIM(CAST(location_type AS STRING)) AS location_type,

        -- Coordinates
        SAFE_CAST(latitude AS FLOAT64) AS latitude,
        SAFE_CAST(longitude AS FLOAT64) AS longitude,
        SAFE_CAST(x_coordinate_state_plane AS INT64) AS x_coordinate_state_plane,
        SAFE_CAST(y_coordinate_state_plane AS INT64) AS y_coordinate_state_plane,

        -- Submission / misc
        TRIM(CAST(open_data_channel_type AS STRING)) AS method_of_submission,
        TRIM(CAST(resolution_description AS STRING)) AS resolution_description,
        TRIM(CAST(vehicle_type AS STRING)) AS vehicle_type,
        SAFE_CAST(bbl AS STRING) AS bbl,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE unique_key IS NOT NULL
      AND created_date IS NOT NULL
      AND complaint_type IS NOT NULL
      AND UPPER(TRIM(CAST(complaint_type AS STRING))) LIKE '%ILLEGAL PARKING%'
),

deduped AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY request_id
        ORDER BY created_date DESC, closed_date DESC
    ) = 1
)

SELECT * FROM deduped