-- models/project_work/marts/fact_311_complaints.sql
{{ config(materialized='table') }}

WITH src AS (
    SELECT *
    FROM {{ ref('stg_nyc_311_illegal_traffic') }}
),

final AS (
    SELECT
        CAST(src.request_id AS INT64) AS unique_key,
        d.date_key,
        l.location_key,
        p.problem_key,
        SAFE_CAST(src.latitude AS FLOAT64) AS latitude,
        SAFE_CAST(src.longitude AS FLOAT64) AS longitude,
        src.status,
        src.created_date AS created_timestamp
    FROM src

    LEFT JOIN {{ ref('dim_date') }} d
        ON CAST(src.created_date AS DATE) = d.full_date

    LEFT JOIN {{ ref('dim_location') }} l
        ON src.borough = l.borough
       AND src.incident_zip = l.zip_code
       AND src.city = l.neighborhood
       AND (
            src.council_district = l.council_district
            OR (src.council_district IS NULL AND l.council_district IS NULL)
       )

    LEFT JOIN {{ ref('dim_311_problem') }} p
        ON src.agency = p.agency
       AND src.complaint_type = p.complaint_type
       AND src.descriptor = p.problem_detail
)

SELECT * FROM final