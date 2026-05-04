{{ config(materialized='table') }}

-- Bus stop dimension input.
-- Union of stops appearing in ACE (with violation context) and Segment endpoints.
-- This is broader than ACE-observed only, which avoids the biased denominator
-- problem when computing per-stop KPIs.

with ace_stops as (
    select
        stop_id,
        any_value(stop_name)            as stop_name,
        any_value(bus_stop_latitude)    as latitude,
        any_value(bus_stop_longitude)   as longitude,
        true                            as observed_in_ace,
        false                           as observed_as_timepoint
    from {{ ref('int_ace__with_geo') }}
    where stop_id is not null
    group by stop_id
),

seg_from_stops as (
    select
        from_stop_id    as stop_id,
        any_value(from_stop_name)       as stop_name,
        any_value(from_stop_latitude)   as latitude,
        any_value(from_stop_longitude)  as longitude,
        false                           as observed_in_ace,
        true                            as observed_as_timepoint
    from {{ ref('int_segment__with_geo') }}
    group by from_stop_id
),

seg_to_stops as (
    select
        to_stop_id      as stop_id,
        any_value(to_stop_name)         as stop_name,
        any_value(to_stop_latitude)     as latitude,
        any_value(to_stop_longitude)    as longitude,
        false                           as observed_in_ace,
        true                            as observed_as_timepoint
    from {{ ref('int_segment__with_geo') }}
    group by to_stop_id
),

unioned as (
    select * from ace_stops
    union all select * from seg_from_stops
    union all select * from seg_to_stops
),

agg as (
    select
        stop_id,
        any_value(stop_name)               as stop_name,
        avg(latitude)                      as latitude,
        avg(longitude)                     as longitude,
        max(observed_in_ace)               as observed_in_ace,
        max(observed_as_timepoint)         as is_timepoint
    from unioned
    where stop_id is not null
      and latitude  is not null
      and longitude is not null
    group by stop_id
)

select
    a.*,
    {{ grid_cell_id('longitude', 'latitude') }} as grid_cell_id
from agg a
