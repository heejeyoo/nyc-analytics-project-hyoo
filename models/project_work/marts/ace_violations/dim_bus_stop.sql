-- models/project_work/marts/dim_bus_stop.sql
{{ config(materialized='table') }}

WITH base AS (
    SELECT DISTINCT
        stop_id,
        stop_name,
        SAFE_CAST(bus_stop_latitude AS FLOAT64) AS bus_stop_latitude,
        SAFE_CAST(bus_stop_longitude AS FLOAT64) AS bus_stop_longitude
    FROM {{ ref('stg_mta_ace_violations') }}
    WHERE stop_id IS NOT NULL
),

bus_stop_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'stop_id',
            'stop_name',
            'CAST(bus_stop_latitude AS STRING)',
            'CAST(bus_stop_longitude AS STRING)'
        ]) }} AS bus_stop_key,
        stop_id,
        stop_name,
        bus_stop_latitude,
        bus_stop_longitude
    FROM base
)

SELECT * FROM bus_stop_dimension