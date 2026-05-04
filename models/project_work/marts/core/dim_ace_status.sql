{{ config(materialized='table') }}

-- Junk dimension for ACE outcome flags.
-- Status was previously incorrectly placed inside Dim_ACE_Violation_Type;
-- it is event-level, not type-level.

with combos as (
    select distinct
        violation_status,
        citation_issued,
        rejection_reason
    from {{ ref('int_ace__with_geo') }}
)

select
    farm_fingerprint(concat(
        coalesce(violation_status, ''), '|',
        cast(citation_issued as string)
    )) as ace_status_key,
    violation_status,
    citation_issued,
    rejection_reason
from combos
