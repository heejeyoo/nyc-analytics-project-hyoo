{{ config(materialized='table') }}

-- KPI #3: Ridership-Weighted Delay Minutes per segment × time window.
-- Delay per trip = (distance / observed_speed) - (distance / freeflow_speed)  [hours]
-- Ridership-weighted delay = delay_per_trip × bus_trip_count × 60  [minutes saved if conflict cleared]

with f as (
    select * from {{ ref('fact_bus_segment_performance') }}
),

bench as (
    select
        segment_id,
        approx_quantiles(case when not is_peak then average_road_speed_mph end, 100)[offset(95)]
            as freeflow_benchmark_mph
    from f group by segment_id
),

joined as (
    select
        f.*,
        b.freeflow_benchmark_mph,
        case
            when f.average_road_speed_mph is null or f.average_road_speed_mph = 0 then null
            when b.freeflow_benchmark_mph is null or b.freeflow_benchmark_mph = 0 then null
            else (f.road_distance_mi / f.average_road_speed_mph)
               - (f.road_distance_mi / b.freeflow_benchmark_mph)
        end                                                                 as delay_hours_per_trip
    from f
    left join bench b using (segment_id)
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
    bus_trip_count,
    road_distance_mi,
    average_road_speed_mph,
    freeflow_benchmark_mph,
    delay_hours_per_trip,
    coalesce(delay_hours_per_trip, 0) * coalesce(bus_trip_count, 0) * 60.0  as ridership_weighted_delay_min
from joined
