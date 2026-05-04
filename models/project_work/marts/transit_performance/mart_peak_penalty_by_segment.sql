{{ config(materialized='table') }}

-- KPI #2: Peak-Hour Speed Penalty per segment × direction.

with peak_avg as (
    select
        segment_id,
        location_key,
        route_key,
        direction,
        avg(average_road_speed_mph) as avg_speed_peak
    from {{ ref('fact_bus_segment_performance') }}
    where is_peak
    group by 1, 2, 3, 4
),

offpeak_avg as (
    select
        segment_id,
        direction,
        avg(average_road_speed_mph) as avg_speed_offpeak
    from {{ ref('fact_bus_segment_performance') }}
    where not is_peak
    group by 1, 2
)

select
    p.segment_id,
    p.location_key,
    p.route_key,
    p.direction,
    p.avg_speed_peak,
    o.avg_speed_offpeak,
    safe_divide(
        o.avg_speed_offpeak - p.avg_speed_peak,
        nullif(o.avg_speed_offpeak, 0)
    )                                       as peak_speed_penalty
from peak_avg p
left join offpeak_avg o using (segment_id, direction)
