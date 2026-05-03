-- models/project_work/marts/fact_ace_violations.sql
{{ config(materialized='table') }}

WITH src AS (
    SELECT *
    FROM {{ ref('stg_mta_ace_violations') }}
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

    LEFT JOIN {{ ref('dim_date_project') }} d
        ON CAST(src.first_occurrence_at AS DATE) = d.full_date

    LEFT JOIN {{ ref('dim_location_project') }} l
        ON src.borough_guess = l.borough
       AND l.zip_code IS NULL
       AND l.council_district IS NULL

    LEFT JOIN {{ ref('dim_ace_violation_type') }} vt
        ON src.violation_type = vt.violation_category
       AND src.violation_status = vt.violation_status

    LEFT JOIN {{ ref('dim_bus_route') }} r
        ON src.bus_route_id = r.bus_route_id

    LEFT JOIN {{ ref('dim_bus_stop') }} bs
        ON src.stop_id = bs.stop_id
       AND src.stop_name = bs.stop_name
)

SELECT * FROM final