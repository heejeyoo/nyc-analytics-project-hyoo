{{ config(materialized='table') }}

-- KPI #5: Conflict-Adjusted Speed Loss = conflict_density × speed_deficit at the same location.
-- Diagnostic mart that defends H-A (conflict signal predicts performance loss).

with conflict as (
    select
        location_key,
        avg(conflict_density) as avg_conflict_density,
        sum(ace_count)        as total_ace,
        sum(c311_count)       as total_311
    from {{ ref('mart_conflict_density_by_h3_day') }}
    group by location_key
),

deficit as (
    select
        location_key,
        avg(bus_speed_deficit) as avg_speed_deficit
    from {{ ref('mart_speed_deficit_by_segment_hour') }}
    where is_peak
    group by location_key
)

select
    coalesce(c.location_key, d.location_key)        as location_key,
    coalesce(c.avg_conflict_density, 0)             as avg_conflict_density,
    coalesce(c.total_ace, 0)                        as total_ace,
    coalesce(c.total_311, 0)                        as total_311,
    coalesce(d.avg_speed_deficit, 0)                as avg_peak_speed_deficit,
    coalesce(c.avg_conflict_density, 0)
        * coalesce(d.avg_speed_deficit, 0)          as conflict_adjusted_speed_loss
from conflict c
full outer join deficit d using (location_key)
