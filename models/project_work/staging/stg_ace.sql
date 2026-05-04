{{ config(materialized='view') }}

-- ============================================================================
-- stg_ace
-- ----------------------------------------------------------------------------
-- Staging model for MTA Automated Camera Enforcement (ACE) violations.
--
-- Job:
--   1. Pull from the raw source table
--   2. Rename columns to snake_case
--   3. Cast columns to the right types
--   4. Drop rows missing required fields (violation id, timestamps, route,
--      bus stop, lat/lng)
--
-- ACE is already a focused dataset (every row is a curb-related event by
-- definition), so we don't need a complaint-type filter here.
-- ============================================================================

with source as (

    select * from {{ source('nyc_proj2_raw_data', 'raw_ace') }}

),

renamed as (

    select
        -- identifier
        cast(violation_id as string)             as violation_id,

        -- timestamps
        cast(first_occurrence as timestamp)      as first_occurrence,
        cast(last_occurrence  as timestamp)      as last_occurrence,

        -- violation classification
        cast(violation_type     as string)       as violation_category,
        cast(violation_status   as string)       as violation_status,

        -- bus context
        cast(bus_route_id   as string)           as bus_route_id,
        cast(stop_id        as string)           as stop_id,
        cast(stop_name      as string)           as stop_name,

        -- location attributes
        cast(borough            as string)       as borough,
        cast(zip_code           as string)       as zip_code,
        cast(neighborhood       as string)       as neighborhood,
        cast(council_district   as int64)        as council_district,

        -- coordinates (kept as degenerate dims on the fact)
        cast(violation_latitude  as float64)     as violation_latitude,
        cast(violation_longitude as float64)     as violation_longitude,
        cast(bus_stop_latitude   as float64)     as bus_stop_latitude,
        cast(bus_stop_longitude  as float64)     as bus_stop_longitude

    from source

),

filtered as (

    select *
    from renamed
    where violation_id     is not null
      and first_occurrence is not null
      and bus_route_id     is not null
      and borough          is not null

)

select * from filtered
