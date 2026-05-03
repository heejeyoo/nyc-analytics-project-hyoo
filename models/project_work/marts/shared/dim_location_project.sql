-- models/project_work/marts/dim_location_project.sql
{{ config(materialized='table') }}

WITH locations_311 AS (
    SELECT DISTINCT
        borough,
        incident_zip AS zip_code,
        city AS neighborhood,
        council_district
    FROM {{ ref('stg_nyc_311_illegal_traffic') }}
    WHERE borough IS NOT NULL
),

locations_ace AS (
    SELECT DISTINCT
        borough_guess AS borough,
        incident_zip AS zip_code,
        neighborhood,
        council_district
    FROM {{ ref('stg_mta_ace_violations') }}
    WHERE borough_guess IS NOT NULL
),

all_locations AS (
    SELECT * FROM locations_311
    UNION DISTINCT
    SELECT * FROM locations_ace
),

location_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'borough',
            'zip_code',
            'neighborhood',
            'CAST(council_district AS STRING)'
        ]) }} AS location_key,
        borough,
        zip_code,
        neighborhood,
        council_district
    FROM all_locations
)

SELECT * FROM location_dimension