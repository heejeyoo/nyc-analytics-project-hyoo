{{ config(materialized='table') }}

-- KPI #6: Enforcement Gap Index = 311_curb / ACE_citations_issued, per location × month.

with ace_monthly as (
    select
        f.location_key,
        d.year,
        d.month,
        sum(f.citation_issued_count) as citations_issued
    from {{ ref('fact_ace_violations') }} f
    join {{ ref('dim_date') }} d using (date_key)
    group by 1, 2, 3
),

c311_monthly as (
    select
        f.location_key,
        d.year,
        d.month,
        sum(f.complaint_count) as complaints_311
    from {{ ref('fact_311_complaints') }} f
    join {{ ref('dim_date') }} d using (date_key)
    group by 1, 2, 3
)

select
    coalesce(a.location_key, c.location_key) as location_key,
    coalesce(a.year,         c.year)         as year,
    coalesce(a.month,        c.month)        as month,
    coalesce(a.citations_issued, 0)          as citations_issued,
    coalesce(c.complaints_311,  0)           as complaints_311,
    safe_divide(coalesce(c.complaints_311, 0), nullif(a.citations_issued, 0)) as enforcement_gap_index
from ace_monthly a
full outer join c311_monthly c using (location_key, year, month)
