-- models/project_work/marts/dim_bus_route.sql
{{ config(materialized='table') }}

WITH base AS (
    SELECT DISTINCT
        bus_route_id,
        'MTA' AS agency_name
    FROM {{ ref('stg_mta_ace_violations') }}
    WHERE bus_route_id IS NOT NULL
),

route_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'bus_route_id',
            'agency_name'
        ]) }} AS route_key,
        bus_route_id,
        agency_name
    FROM base
)

SELECT * FROM route_dimension