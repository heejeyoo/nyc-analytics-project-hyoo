-- models/project_work/marts/dim_ace_violation_type.sql
{{ config(materialized='table') }}

WITH base AS (
    SELECT DISTINCT
        violation_type AS violation_category,
        violation_status
    FROM {{ ref('stg_mta_ace_violations') }}
    WHERE violation_type IS NOT NULL
),

violation_type_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'violation_category',
            'violation_status'
        ]) }} AS violation_type_key,
        violation_category,
        violation_status
    FROM base
)

SELECT * FROM violation_type_dimension