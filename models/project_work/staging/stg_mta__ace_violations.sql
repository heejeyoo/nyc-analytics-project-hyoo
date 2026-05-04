{{ config(materialized='view') }}

-- Staging: MTA ACE violations.
-- Deduped to one row per violation_id (most recent last_occurrence wins).
-- Rows with NULL bus_route_id are dropped — they cannot join to Dim_Bus_Route.

with src as (
    select * from {{ source('nyc_proj2_raw_data', 'source_mta_ace_violations') }}
),

typed as (
    select
        cast(violation_id as string)                                            as violation_id,
        cast(bus_route_id as string)                                            as bus_route_id,
        cast(stop_id as string)                                                 as stop_id,
        cast(stop_name as string)                                               as stop_name,
        cast(violation_type as string)                                          as violation_type,
        cast(violation_status as string)                                        as violation_status,
        cast(first_occurrence as timestamp)                                     as first_occurrence,
        cast(last_occurrence as timestamp)                                      as last_occurrence,
        safe_cast(violation_latitude  as float64)                               as violation_latitude,
        safe_cast(violation_longitude as float64)                               as violation_longitude,
        safe_cast(bus_stop_latitude   as float64)                               as bus_stop_latitude,
        safe_cast(bus_stop_longitude  as float64)                               as bus_stop_longitude,
        cast(vehicle_id as string)                                              as vehicle_id
    from src
),

filtered as (
    select *
    from typed
    where violation_latitude  is not null
      and violation_longitude is not null
      and violation_id        is not null
      and bus_route_id        is not null
      and trim(bus_route_id) != ''
)

select *
from filtered
qualify row_number() over (
    partition by violation_id
    order by last_occurrence desc, first_occurrence desc
) = 1