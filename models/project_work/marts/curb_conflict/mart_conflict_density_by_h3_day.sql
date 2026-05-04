{{ config(materialized='table') }}

-- KPI #4: Curb Conflict Density (z-scored ACE + 311 counts) at grid × day grain.

with ace_counts as (
    select location_key, date_key,
           sum(violation_count) as ace_count
    from {{ ref('fact_ace_violations') }}
    group by 1, 2
),

c311_counts as (
    select location_key, date_key,
           sum(complaint_count) as c311_count
    from {{ ref('fact_311_complaints') }}
    group by 1, 2
),

joined as (
    select
        coalesce(a.location_key, c.location_key)    as location_key,
        coalesce(a.date_key,     c.date_key)        as date_key,
        coalesce(a.ace_count, 0)                    as ace_count,
        coalesce(c.c311_count, 0)                   as c311_count
    from ace_counts a
    full outer join c311_counts c using (location_key, date_key)
),

stats as (
    select
        avg(ace_count)              as ace_mean,
        stddev_pop(ace_count)       as ace_sd,
        avg(c311_count)             as c311_mean,
        stddev_pop(c311_count)      as c311_sd
    from joined
)

select
    j.location_key,
    j.date_key,
    j.ace_count,
    j.c311_count,
    safe_divide(j.ace_count  - s.ace_mean,  nullif(s.ace_sd, 0))     as z_ace,
    safe_divide(j.c311_count - s.c311_mean, nullif(s.c311_sd, 0))    as z_311,
    (
        coalesce(safe_divide(j.ace_count  - s.ace_mean,  nullif(s.ace_sd, 0)), 0) +
        coalesce(safe_divide(j.c311_count - s.c311_mean, nullif(s.c311_sd, 0)), 0)
    ) / 2.0                                                          as conflict_density
from joined j
cross join stats s
