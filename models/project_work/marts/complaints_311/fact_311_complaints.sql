{{ config(materialized='table') }}

-- ============================================================================
-- fact_311_complaints
-- ----------------------------------------------------------------------------
-- Fact table: one row per 311 curb-related complaint.
--
-- Foreign keys:
--   - date_key      → dim_date
--   - location_key  → dim_location
--   - problem_key   → dim_311_problem
--
-- Degenerate dimensions / measures:
--   - latitude, longitude (kept on the fact for optional mapping)
--   - status (Open/Closed)
--   - created_date (the natural timestamp)
-- ============================================================================

with stg as (

    select * from {{ ref('stg_311') }}

),

with_date_key as (

    -- Compute date_key inline as YYYYMMDDHH integer (matches dim_date PK).
    -- Truncating to the hour aligns each complaint with its matching
    -- dim_date row at hour grain.
    select
        s.*,
        cast(
            format_timestamp('%Y%m%d%H', timestamp_trunc(s.created_at, hour))
            as int64
        ) as date_key
    from stg s

),

joined as (

    select
        s.complaint_id           as unique_key,
        s.date_key,
        loc.location_key,
        prob.problem_key,

        -- degenerate dims & measures
        s.latitude,
        s.longitude,
        s.status,
        s.created_at             as created_date

    from with_date_key s
    left join {{ ref('dim_location') }} loc
        on  coalesce(s.borough,           '~') = coalesce(loc.borough,           '~')
        and coalesce(s.zip_code,          '~') = coalesce(loc.zip_code,          '~')
        and coalesce(s.neighborhood,      '~') = coalesce(loc.neighborhood,      '~')
        and coalesce(s.council_district,  -1)  = coalesce(loc.council_district,  -1)
    left join {{ ref('dim_311_problem') }} prob
        on  coalesce(s.agency,         '~') = coalesce(prob.agency,         '~')
        and coalesce(s.complaint_type, '~') = coalesce(prob.complaint_type, '~')
        and coalesce(s.problem_detail, '~') = coalesce(prob.problem_detail, '~')

)

select * from joined
