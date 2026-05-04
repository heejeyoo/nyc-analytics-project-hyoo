{{ config(materialized='view') }}

-- ============================================================================
-- stg_311
-- ----------------------------------------------------------------------------
-- Staging model for NYC 311 service requests.
--
-- Job:
--   1. Pull from the raw source table
--   2. Rename columns to snake_case
--   3. Cast columns to the right types
--   4. Filter to curb-related complaint types only (the ones that affect
--      bus service: double parking, blocked bus stop, blocked driveway,
--      illegal parking)
--   5. Drop rows missing required fields (complaint id, created date, location)
--
-- No joins, no business logic, no derived metrics. Just a clean view of
-- the raw 311 data, ready for the dimension and fact layers to consume.
-- ============================================================================

with source as (

    select * from {{ source('nyc_proj2_raw_data', 'raw_311') }}

),

renamed as (

    select
        -- identifiers
        cast(unique_key as int64)        as complaint_id,

        -- timestamps
        cast(created_date as timestamp)  as created_at,
        cast(closed_date  as timestamp)  as closed_at,

        -- complaint description
        cast(agency           as string) as agency,
        cast(complaint_type   as string) as complaint_type,
        cast(descriptor       as string) as problem_detail,
        cast(status           as string) as status,

        -- location attributes
        cast(borough            as string) as borough,
        cast(incident_zip       as string) as zip_code,
        cast(community_board    as string) as neighborhood,
        cast(council_district   as int64)  as council_district,

        -- raw coordinates (kept as degenerate dims on the fact)
        cast(latitude  as float64) as latitude,
        cast(longitude as float64) as longitude

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

)

select * from filtered
