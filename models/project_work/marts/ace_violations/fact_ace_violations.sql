-- Grain: one row per violation_id
-- Note: dimension joins are deduplicated before joining to avoid fanout
{{ config(materialized='table') }}

WITH src AS (
    SELECT *
    FROM {{ ref('stg_mta_ace_violations') }}
),

date_dim AS (
    SELECT DISTINCT
        date_key,
        full_date
    FROM {{ ref('dim_date_project') }}
),

location_dim AS (
    SELECT *
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY borough
                ORDER BY location_key
            ) AS rn
        FROM {{ ref('dim_location_project') }}
    )
    WHERE rn = 1
),

violation_type_dim AS (
    SELECT *
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY violation_category, violation_status
                ORDER BY violation_type_key
            ) AS rn
        FROM {{ ref('dim_ace_violation_type') }}
    )
    WHERE rn = 1
),

route_dim AS (
    SELECT *
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY bus_route_id
                ORDER BY route_key
            ) AS rn
        FROM {{ ref('dim_bus_route') }}
    )
    WHERE rn = 1
),

bus_stop_dim AS (
    SELECT *
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY stop_id, stop_name
                ORDER BY bus_stop_key
            ) AS rn
        FROM {{ ref('dim_bus_stop') }}
    )
    WHERE rn = 1
),

final AS (
    SELECT
        src.violation_id,
        d.date_key AS violation_date_key,
        l.location_key,
        vt.violation_type_key,
        r.route_key,
        bs.bus_stop_key,
        SAFE_CAST(src.violation_latitude AS FLOAT64) AS violation_latitude,
        SAFE_CAST(src.violation_longitude AS FLOAT64) AS violation_longitude,
        src.stop_id AS source_bus_stop_id,
        src.first_occurrence_at AS first_occurrence,
        src.last_occurrence_at AS last_occurrence
    FROM src
    LEFT JOIN date_dim d
        ON CAST(src.first_occurrence_at AS DATE) = d.full_date
    LEFT JOIN location_dim l
        ON src.borough_guess = l.borough
    LEFT JOIN violation_type_dim vt
        ON src.violation_type = vt.violation_category
       AND src.violation_status = vt.violation_status
    LEFT JOIN route_dim r
        ON src.bus_route_id = r.bus_route_id
    LEFT JOIN bus_stop_dim bs
        ON src.stop_id = bs.stop_id
       AND src.stop_name = bs.stop_name
),

deduped AS (
    SELECT *
    FROM final
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY violation_id
        ORDER BY last_occurrence DESC, first_occurrence DESC
    ) = 1
)

SELECT * FROM deduped