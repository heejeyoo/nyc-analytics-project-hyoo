{{ config(materialized='view') }}

-- Staging: MTA Bus Automated Camera Enforcement violations.
-- 1:1 with raw source except for typing and renaming.

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
)

select *
from typed
where violation_latitude  is not null
  and violation_longitude is not null
