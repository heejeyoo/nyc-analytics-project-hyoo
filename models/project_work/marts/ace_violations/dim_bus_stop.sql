{{ config(materialized='table') }}

-- ============================================================================
-- dim_bus_stop
-- ----------------------------------------------------------------------------
-- Mart-specific dimension for Fact_ACE_Violations.
--
-- Grain: one row per unique stop_id.
--
-- Lets analysts identify bus stops with the most violation activity.
-- Lat/lng are kept as attributes (not as join keys) for mapping.
-- ============================================================================

with distinct_stops as (

    select
        stop_id,
        any_value(stop_name)            as stop_name,
        any_value(bus_stop_latitude)    as bus_stop_latitude,
        any_value(bus_stop_longitude)   as bus_stop_longitude
    from {{ ref('stg_ace') }}
    where stop_id is not null
    group by stop_id

)

select
    row_number() over (order by stop_id) as bus_stop_key,
    stop_id,
    stop_name,
    bus_stop_latitude,
    bus_stop_longitude
from distinct_stops
