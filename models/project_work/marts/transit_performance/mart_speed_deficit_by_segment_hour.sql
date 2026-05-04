{{ config(materialized='table') }}

-- KPI #1: Bus Speed Deficit per segment × hour.
-- Free-flow benchmark = 95th percentile observed speed for that segment,
-- restricted to off-peak hours.

with f as (
    select * from {{ ref('fact_bus_segment_performance') }}
),

benchmarks as (
    select
        segment_id,
        approx_quantiles(case when not is_peak then average_road_speed_mph end, 100)[offset(95)]
            as freeflow_benchmark_mph
    from f
    group by segment_id
),

joined as (
    select
        f.*,
        b.freeflow_benchmark_mph
    from f
    left join benchmarks b using (segment_id)
)

select
    segment_perf_key,
    segment_id,
    location_key,
    route_key,
    date_key,
    time_key,
    direction,
    is_peak,
    peak_period,
    average_road_speed_mph,
    freeflow_benchmark_mph,
    safe_divide(
        freeflow_benchmark_mph - average_road_speed_mph,
        nullif(freeflow_benchmark_mph, 0)
    )                                                                       as bus_speed_deficit,
    bus_trip_count,
    road_distance_mi,
    average_travel_time_min
from joined
