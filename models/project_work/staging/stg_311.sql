{{ config(materialized='view') }}

-- ============================================================================
-- stg_311
-- ----------------------------------------------------------------------------
-- Staging model for NYC 311 service requests.
--
-- Job:
--   1. Pull from the raw source table (everything is STRING in raw)
--   2. Rename columns to snake_case (already are) and cast to real types
--   3. Filter to curb-related complaint types only (the ones that affect
--      bus service: double parking, blocked bus stop, blocked driveway,
--      illegal parking, blocked bike lane, posted parking sign violation)
--   4. Drop rows missing required fields (complaint id, created date,
--      borough, complaint type)
--
-- Note: raw_data column types are all STRING in the source, so we use
-- safe_cast() — bad rows return NULL instead of failing the whole query.
-- ============================================================================

with source as (

    select * from {{ source('nyc_proj2_raw_data', 'source_nyc_311_traffic') }}

),

renamed as (

    select
        -- identifier
        safe_cast(unique_key as int64)              as complaint_id,

        -- timestamps
        safe_cast(created_date as timestamp)        as created_at,
        safe_cast(closed_date  as timestamp)        as closed_at,

        -- complaint description
        agency                                       as agency,
        complaint_type                               as complaint_type,
        descriptor                                   as problem_detail,
        status                                       as status,

        -- location attributes (normalize borough to UPPERCASE so it lines
        -- up with the borough values derived in stg_ace)
        upper(borough)                               as borough,
        incident_zip                                 as zip_code,
        community_board                              as neighborhood,
        safe_cast(council_district as int64)         as council_district,

        -- raw coordinates (kept as degenerate dims on the fact)
        safe_cast(latitude  as float64)              as latitude,
        safe_cast(longitude as float64)              as longitude

    from source

),

filtered as (

    select *
    from renamed
    where complaint_id  is not null
      and created_at    is not null
      and borough       is not null
      and complaint_type in (
            'Illegal Parking',
            'Blocked Driveway',
            'Double Parked Blocking Vehicle',
            'Double Parked Blocking Traffic',
            'Blocked Bike Lane',
            'Posted Parking Sign Violation'
      )

),

deduplicated as (

    -- Raw 311 exports occasionally republish the same complaint across
    -- daily snapshots. Keep the most recent version of each complaint_id
    -- so the PK is truly unique.
    select *
    from filtered
    qualify row_number() over (
        partition by complaint_id
        order by coalesce(closed_at, created_at) desc
    ) = 1

)

select * from deduplicated
