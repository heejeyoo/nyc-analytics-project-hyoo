{{ config(materialized='table') }}

-- Conformed Bus Route dimension.
-- Includes has_ace_camera flag (critical: ACE volume is conditional on camera presence).

select
    farm_fingerprint(bus_route_id)              as route_key,
    bus_route_id,
    upper(route_type)                           as route_type,
    is_sbs,
    has_ace_camera,
    primary_borough_from_prefix,
    agency_name
from {{ ref('int_routes__enriched') }}
