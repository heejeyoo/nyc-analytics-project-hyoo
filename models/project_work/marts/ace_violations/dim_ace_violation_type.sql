{{ config(materialized='table') }}

-- ============================================================================
-- dim_ace_violation_type
-- ----------------------------------------------------------------------------
-- Mart-specific dimension for Fact_ACE_Violations.
--
-- Grain: one row per unique combination of (violation_category, violation_status).
--
-- Lets analysts split ACE facts by what kind of violation it was
-- (Bus Stop vs Bus Lane vs Double Parked) and whether it resulted in
-- a citation or was rejected.
-- ============================================================================

with distinct_types as (

    select distinct
        violation_category,
        violation_status
    from {{ ref('stg_ace') }}

)

select
    row_number() over (
        order by violation_category, violation_status
    ) as violation_type_key,

    violation_category,
    violation_status

from distinct_types
