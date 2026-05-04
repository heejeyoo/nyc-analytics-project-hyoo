{{ config(materialized='table') }}

-- ============================================================================
-- fact_ace_violations
-- ----------------------------------------------------------------------------
-- Fact table: one row per MTA ACE camera violation event.
--
-- Foreign keys:
--   - date_key            → dim_date
--   - location_key        → dim_location
--   - violation_type_key  → dim_ace_violation_type
--   - route_key           → dim_bus_route
--   - bus_stop_key        → dim_bus_stop
--
-- Degenerate dimensions / measures:
--   - violation_latitude, violation_longitude (kept on fact for mapping)
--   - first_occurrence, last_occurrence
--   - duration_minutes (derived measure)
-- ============================================================================

with stg as (

    select * from {{ ref('stg_ace') }}

),

with_date_key as (

    -- Compute date_key inline as YYYYMMDDHH integer to match dim_date PK.
    -- Anchors the violation on its first_occurrence (when it was detected).
    select
        s.*,
        cast(
            format_timestamp('%Y%m%d%H', timestamp_trunc(s.first_occurrence, hour))
            as int64
        ) as date_key
    from stg s

),

joined as (

    select
        s.violation_id,
        s.date_key,
        loc.location_key,
        vtype.violation_type_key,
        route.route_key,
        stop.bus_stop_key,

        -- degenerate dims & measures
        s.violation_latitude,
        s.violation_longitude,
        s.first_occurrence,
        s.last_occurrence,
        timestamp_diff(s.last_occurrence, s.first_occurrence, minute)
            as duration_minutes

    from with_date_key s
    left join {{ ref('dim_location') }} loc
        on  coalesce(s.borough,           '~') = coalesce(loc.borough,           '~')
        and coalesce(s.zip_code,          '~') = coalesce(loc.zip_code,          '~')
        and coalesce(s.neighborhood,      '~') = coalesce(loc.neighborhood,      '~')
        and coalesce(s.council_district,  -1)  = coalesce(loc.council_district,  -1)
    left join {{ ref('dim_ace_violation_type') }} vtype
        on  coalesce(s.violation_category, '~') = coalesce(vtype.violation_category, '~')
        and coalesce(s.violation_status,   '~') = coalesce(vtype.violation_status,   '~')
    left join {{ ref('dim_bus_route') }} route
        on s.bus_route_id = route.bus_route_id
    left join {{ ref('dim_bus_stop') }} stop
        on s.stop_id = stop.stop_id

)

select * from joined
