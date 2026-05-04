{{ config(materialized='table') }}

-- ACE violations enriched with grid_cell_id, derived borough (from spatial grid + route fallback),
-- citation flag, and event hour.

with src as (
    select * from {{ ref('stg_mta__ace_violations') }}
),

enriched as (
    select
        src.*,
        {{ grid_cell_id('violation_longitude', 'violation_latitude') }}     as grid_cell_id,
        {{ grid_cell_centroid_lat('violation_latitude') }}                  as grid_lat,
        {{ grid_cell_centroid_lon('violation_longitude') }}                 as grid_lon,
        extract(date from first_occurrence)                                 as event_date,
        extract(hour from first_occurrence)                                 as event_hour,
        {{ peak_period('extract(hour from first_occurrence)') }}            as peak_period,
        {{ is_peak('extract(hour from first_occurrence)') }}                as is_peak,
        case
            when upper(violation_status) like '%CITATION ISSUED%' then true
            else false
        end                                                                 as citation_issued,
        case
            when upper(violation_status) like '%CITATION ISSUED%' then null
            else violation_status
        end                                                                 as rejection_reason,
        {{ borough_from_route_prefix('bus_route_id') }}                     as borough_from_route
    from src
)

select * from enriched
