{{ config(materialized='table') }}

-- Fact-specific dimension for 311 complaint classification.

with raw_combos as (
    select distinct
        agency,
        agency_name,
        complaint_type,
        descriptor,
        problem_category
    from {{ ref('int_311__with_geo') }}
)

select
    farm_fingerprint(concat(
        coalesce(agency, ''), '|',
        coalesce(complaint_type, ''), '|',
        coalesce(descriptor, '')
    )) as problem_key,
    agency,
    agency_name,
    complaint_type,
    descriptor                  as problem_detail,
    problem_category
from raw_combos
