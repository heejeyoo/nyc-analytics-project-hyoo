{{ config(materialized='table') }}

-- HEADLINE MART — KPI #7: Squeeze Index per location.
-- Squeeze Index = w1·peak_penalty_norm + w2·conflict_norm + w3·ridership_norm
-- where each component is min-max normalized across all observed locations,
-- and weights are configured in dbt_project.yml vars.

with peak as (
    select
        location_key,
        avg(peak_speed_penalty) as peak_speed_penalty
    from {{ ref('mart_peak_penalty_by_segment') }}
    group by location_key
),

conflict as (
    select
        location_key,
        avg(conflict_density)   as conflict_density
    from {{ ref('mart_conflict_density_by_h3_day') }}
    group by location_key
),

ridership as (
    select
        location_key,
        sum(ridership_weighted_delay_min) as ridership_weighted_delay_min
    from {{ ref('mart_ridership_weighted_delay') }}
    group by location_key
),

joined as (
    select
        coalesce(p.location_key, c.location_key, r.location_key)    as location_key,
        coalesce(p.peak_speed_penalty, 0)                           as peak_speed_penalty,
        coalesce(c.conflict_density, 0)                             as conflict_density,
        coalesce(r.ridership_weighted_delay_min, 0)                 as ridership_weighted_delay_min
    from peak p
    full outer join conflict  c using (location_key)
    full outer join ridership r using (location_key)
),

bounds as (
    select
        min(peak_speed_penalty)             as min_peak,    max(peak_speed_penalty)             as max_peak,
        min(conflict_density)               as min_conf,    max(conflict_density)               as max_conf,
        min(ridership_weighted_delay_min)   as min_ride,    max(ridership_weighted_delay_min)   as max_ride
    from joined
),

normed as (
    select
        j.location_key,
        j.peak_speed_penalty,
        j.conflict_density,
        j.ridership_weighted_delay_min,
        safe_divide(j.peak_speed_penalty - b.min_peak,            nullif(b.max_peak - b.min_peak, 0))   as peak_norm,
        safe_divide(j.conflict_density   - b.min_conf,            nullif(b.max_conf - b.min_conf, 0))   as conflict_norm,
        safe_divide(j.ridership_weighted_delay_min - b.min_ride,  nullif(b.max_ride - b.min_ride, 0))   as ridership_norm
    from joined j
    cross join bounds b
)

select
    n.location_key,
    l.grid_cell_id,
    l.borough,
    l.zip_code,
    l.council_district,
    n.peak_speed_penalty,
    n.conflict_density,
    n.ridership_weighted_delay_min,
    coalesce(n.peak_norm,     0) as peak_norm,
    coalesce(n.conflict_norm, 0) as conflict_norm,
    coalesce(n.ridership_norm, 0) as ridership_norm,
    {{ var('weight_peak_penalty') }} * coalesce(n.peak_norm,     0)
      + {{ var('weight_conflict')      }} * coalesce(n.conflict_norm, 0)
      + {{ var('weight_ridership')     }} * coalesce(n.ridership_norm, 0)
        as squeeze_index
from normed n
left join {{ ref('dim_location') }} l using (location_key)
