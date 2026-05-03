-- models/project_work/marts/dim_date_project.sql
{{ config(materialized='table') }}

WITH all_dates AS (

    SELECT DISTINCT CAST(created_date AS DATE) AS full_date
    FROM {{ ref('stg_nyc_311_illegal_traffic') }}
    WHERE created_date IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT CAST(first_occurrence_at AS DATE) AS full_date
    FROM {{ ref('stg_mta_ace_violations') }}
    WHERE first_occurrence_at IS NOT NULL
),

date_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['full_date']) }} AS date_key,
        full_date,
        EXTRACT(YEAR FROM full_date) AS year,
        EXTRACT(MONTH FROM full_date) AS month,
        EXTRACT(DAY FROM full_date) AS day,
        FORMAT_DATE('%A', full_date) AS day_of_week
    FROM all_dates
)

SELECT * FROM date_dimension