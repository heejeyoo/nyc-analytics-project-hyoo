{{ config(materialized='table') }}

-- ============================================================================
-- dim_311_problem
-- ----------------------------------------------------------------------------
-- Mart-specific dimension for Fact_311_Complaints.
--
-- Grain: one row per unique combination of
--        (agency, complaint_type, problem_detail).
--
-- Lets analysts slice 311 facts by who handles it (NYPD vs DOT vs DSNY),
-- what kind of complaint it is, and the more specific descriptor.
-- ============================================================================

with distinct_problems as (

    select distinct
        agency,
        complaint_type,
        problem_detail
    from {{ ref('stg_311') }}

)

select
    row_number() over (
        order by agency, complaint_type, problem_detail
    ) as problem_key,

    agency,
    complaint_type,
    problem_detail

from distinct_problems
