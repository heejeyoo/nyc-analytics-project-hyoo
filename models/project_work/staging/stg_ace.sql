{{ config(materialized='view') }}

-- ============================================================================
-- stg_ace
-- ----------------------------------------------------------------------------
-- Staging model for MTA Automated Camera Enforcement (ACE) violations.
--
-- Job:
--   1. Pull from the raw source table (everything is STRING in raw)
--   2. Cast columns to the right types using safe_cast (NULL on failure)
--   3. Derive a coarse `borough` from the bus_route_id prefix, since the
--      raw ACE table doesn't carry borough/zip/neighborhood directly.
--      Convention used by MTA route IDs:
--        M*  → Manhattan
--        B*  → Brooklyn   (but Bx* → Bronx)
--        Q*  → Queens
--        S*  → Staten Island
--        BxM*, QM*, BM*, X* → Express (multi-borough; bucketed as 'Express')
--   4. Drop rows missing required fields (violation id, first_occurrence,
--      bus_route_id)
--
-- Note: raw types are all STRING in source, so we use safe_cast()
-- everywhere — bad values return NULL instead of failing the whole query.
-- ============================================================================

with source as (

    select * from {{ source('nyc_proj2_raw_data', 'source_mta_ace_violations') }}

),

renamed as (

    select
        -- identifier
        violation_id                                  as violation_id,

        -- timestamps
        safe_cast(first_occurrence as timestamp)      as first_occurrence,
        safe_cast(last_occurrence  as timestamp)      as last_occurrence,

        -- violation classification
        violation_type                                as violation_category,
        violation_status                              as violation_status,

        -- bus context
        bus_route_id                                  as bus_route_id,
        stop_id                                       as stop_id,
        stop_name                                     as stop_name,

        -- coordinates (degenerate dims on the fact)
        safe_cast(violation_latitude  as float64)     as violation_latitude,
        safe_cast(violation_longitude as float64)     as violation_longitude,
        safe_cast(bus_stop_latitude   as float64)     as bus_stop_latitude,
        safe_cast(bus_stop_longitude  as float64)     as bus_stop_longitude

    from source

),

with_borough as (

    -- Derive a coarse borough from the bus_route_id prefix. Acknowledged
    -- limitation: this is a route-level approximation, not an event-level
    -- location. Good enough for borough-grain analysis at academic scope.
    select
        r.*,
        case
            when upper(r.bus_route_id) like 'BX%'                            then 'BRONX'
            when upper(r.bus_route_id) like 'BM%' or upper(r.bus_route_id) like 'QM%' or upper(r.bus_route_id) like 'X%'
                                                                             then 'EXPRESS'
            when upper(r.bus_route_id) like 'M%'                             then 'MANHATTAN'
            when upper(r.bus_route_id) like 'B%'                             then 'BROOKLYN'
            when upper(r.bus_route_id) like 'Q%'                             then 'QUEENS'
            when upper(r.bus_route_id) like 'S%'                             then 'STATEN ISLAND'
            else 'UNKNOWN'
        end                                            as borough,

        -- Other location attributes are not available on the ACE source.
        -- Carrying as NULL so the join into dim_location still succeeds
        -- (every ACE row maps to one (borough, NULL, NULL, NULL) location).
        cast(null as string)                           as zip_code,
        cast(null as string)                           as neighborhood,
        cast(null as int64)                            as council_district

    from renamed r

),

filtered as (

    select *
    from with_borough
    where violation_id     is not null
      and first_occurrence is not null
      and bus_route_id     is not null

)

select * from filtered
