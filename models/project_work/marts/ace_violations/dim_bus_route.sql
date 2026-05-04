{{ config(materialized='table') }}

-- ============================================================================
-- dim_bus_route
-- ----------------------------------------------------------------------------
-- Mart-specific dimension for Fact_ACE_Violations.
--
-- Grain: one row per unique bus_route_id.
--
-- Lets analysts rank bus routes by violation activity. agency_name is
-- defaulted to 'MTA' since this dataset only contains MTA routes.
-- ============================================================================

with distinct_routes as (

    select distinct
        bus_route_id
    from {{ ref('stg_ace') }}
    where bus_route_id is not null

)

select
    row_number() over (order by bus_route_id) as route_key,
    bus_route_id,
    'MTA' as agency_name
from distinct_routes
