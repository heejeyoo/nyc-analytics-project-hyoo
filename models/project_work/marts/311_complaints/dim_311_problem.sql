-- models/project_work/marts/dim_311_problem.sql
{{ config(materialized='table') }}

WITH base AS (
    SELECT DISTINCT
        agency,
        complaint_type,
        descriptor AS problem_detail
    FROM {{ ref('stg_nyc_311_illegal_traffic') }}
    WHERE agency IS NOT NULL
      AND complaint_type IS NOT NULL
),

problem_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'agency',
            'complaint_type',
            'problem_detail'
        ]) }} AS problem_key,
        agency,
        complaint_type,
        problem_detail
    FROM base
)

SELECT * FROM problem_dimension