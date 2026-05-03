-- models/project_work/staging/stg_mta_ace_violations.sql
-- Clean and standardize MTA ACE Violations data

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_mta_ace_violations') }}
),

cleaned AS (
    SELECT
        -- Identifiers
        CAST(violation_id AS STRING) AS violation_id,
        CAST(bus_route_id AS STRING) AS bus_route_id,
        CAST(vehicle_id AS STRING) AS vehicle_id,
        CAST(stop_id AS STRING) AS stop_id,

        -- Timestamps
        CAST(first_occurrence AS TIMESTAMP) AS first_occurrence_at,
        CAST(last_occurrence AS TIMESTAMP) AS last_occurrence_at,

        -- Descriptions
        UPPER(TRIM(violation_type)) AS violation_type,
        UPPER(TRIM(violation_status)) AS violation_status,
        UPPER(TRIM(stop_name)) AS stop_name,

        -- Geographic Coordinates (Violation Location)
        SAFE_CAST(violation_latitude AS NUMERIC) AS violation_latitude,
        SAFE_CAST(violation_longitude AS NUMERIC) AS violation_longitude,
        violation_georeference,

        -- Geographic Coordinates (Bus Stop Location)
        SAFE_CAST(bus_stop_latitude AS NUMERIC) AS bus_stop_latitude,
        SAFE_CAST(bus_stop_longitude AS NUMERIC) AS bus_stop_longitude,
        bus_stop_georeference,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Basic Data Quality Filters
    WHERE violation_id IS NOT NULL
      AND first_occurrence IS NOT NULL

    -- Deduplication: Keep the record with the most recent occurrence update
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY violation_id
        ORDER BY last_occurrence DESC
    ) = 1
)

SELECT * FROM cleaned