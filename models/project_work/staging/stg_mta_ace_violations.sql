{{ config(materialized='table') }}

WITH source AS (
    SELECT *
    FROM {{ source('raw', 'source_mta_ace_violations') }}
),

cleaned AS (
    SELECT
        -- Primary identifier
        CAST(violation_id AS STRING) AS violation_id,

        -- Route / stop / vehicle identifiers
        TRIM(CAST(bus_route_id AS STRING)) AS bus_route_id,
        TRIM(CAST(stop_id AS STRING)) AS stop_id,
        UPPER(TRIM(CAST(stop_name AS STRING))) AS stop_name,
        CAST(vehicle_id AS STRING) AS vehicle_id,

        -- Timestamps
        CAST(first_occurrence AS TIMESTAMP) AS first_occurrence_at,
        CAST(last_occurrence AS TIMESTAMP) AS last_occurrence_at,

        -- Violation dimensions
        UPPER(TRIM(CAST(violation_type AS STRING))) AS violation_type,
        UPPER(TRIM(CAST(violation_status AS STRING))) AS violation_status,

        -- Violation coordinates
        SAFE_CAST(violation_latitude AS FLOAT64) AS violation_latitude,
        SAFE_CAST(violation_longitude AS FLOAT64) AS violation_longitude,
        CAST(violation_georeference AS STRING) AS violation_georeference,

        -- Bus stop coordinates
        SAFE_CAST(bus_stop_latitude AS FLOAT64) AS bus_stop_latitude,
        SAFE_CAST(bus_stop_longitude AS FLOAT64) AS bus_stop_longitude,
        CAST(bus_stop_georeference AS STRING) AS bus_stop_georeference,

        -- Coarse location enrichment for later Dim_Location support
        CASE
            WHEN SAFE_CAST(bus_stop_longitude AS FLOAT64) BETWEEN -74.05 AND -73.90
             AND SAFE_CAST(bus_stop_latitude AS FLOAT64) BETWEEN 40.68 AND 40.88 THEN 'Manhattan'
            WHEN SAFE_CAST(bus_stop_longitude AS FLOAT64) BETWEEN -73.93 AND -73.76
             AND SAFE_CAST(bus_stop_latitude AS FLOAT64) BETWEEN 40.54 AND 40.80 THEN 'Brooklyn'
            WHEN SAFE_CAST(bus_stop_longitude AS FLOAT64) BETWEEN -73.96 AND -73.70
             AND SAFE_CAST(bus_stop_latitude AS FLOAT64) BETWEEN 40.54 AND 40.80 THEN 'Queens'
            WHEN SAFE_CAST(bus_stop_longitude AS FLOAT64) BETWEEN -73.93 AND -73.77
             AND SAFE_CAST(bus_stop_latitude AS FLOAT64) BETWEEN 40.79 AND 40.92 THEN 'Bronx'
            WHEN SAFE_CAST(bus_stop_longitude AS FLOAT64) BETWEEN -74.25 AND -74.05
             AND SAFE_CAST(bus_stop_latitude AS FLOAT64) BETWEEN 40.48 AND 40.65 THEN 'Staten Island'
            ELSE NULL
        END AS borough_guess,

        CAST(NULL AS STRING) AS incident_zip,
        CAST(NULL AS STRING) AS neighborhood,
        CAST(NULL AS INT64) AS council_district,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE violation_id IS NOT NULL
      AND first_occurrence IS NOT NULL
),

deduped AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY violation_id
        ORDER BY last_occurrence_at DESC, first_occurrence_at DESC
    ) = 1
)

SELECT * FROM deduped