{{ config(materialized='table') }}

-- Fact-specific dimension for ACE violation classes.

with combos as (
    select distinct
        violation_type as violation_category
    from {{ ref('int_ace__with_geo') }}
)

select
    farm_fingerprint(coalesce(violation_category, ''))  as violation_type_key,
    violation_category
from combos
