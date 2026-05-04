{{ config(materialized='table') }}

-- Conformed Bus Stop dimension.
-- Sourced from union of ACE-observed stops and Segment-endpoint timepoints,
-- avoiding the ACE-only biased denominator.

select
    farm_fingerprint(s.stop_id)             as bus_stop_key,
    s.stop_id,
    s.stop_name,
    s.latitude                              as bus_stop_latitude,
    s.longitude                             as bus_stop_longitude,
    s.is_timepoint,
    s.observed_in_ace,
    l.location_key,
    l.borough
from {{ ref('int_stops__unioned') }} s
left join {{ ref('dim_location') }} l on s.grid_cell_id = l.grid_cell_id
