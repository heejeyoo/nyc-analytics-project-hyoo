{{ config(materialized='table') }}

-- Fact: bus segment performance.
-- Grain: route × segment × direction × hour × day_of_week × month × year.
-- date_key here is synthesized from year + month + first day of month
-- because raw segment data is monthly-binned, not daily.

with src as (
    select * from {{ ref('int_segment__with_geo') }}
)

select
    farm_fingerprint(concat(
        s.segment_id, '|',
        cast(s.year as string), '-',
        cast(s.month as string), '-',
        coalesce(s.day_of_week, '?'), '|',
        cast(s.hour_of_day as string)
    ))                                                      as segment_perf_key,

    -- Date key uses first of month since segment data is monthly-aggregated.
    cast(format_date('%Y%m%d',
        date(s.year, s.month, 1)
    ) as int64)                                             as date_key,
    s.hour_of_day                                           as time_key,

    l.location_key                                          as location_key,
    r.route_key                                             as route_key,
    fs.bus_stop_key                                         as from_stop_key,
    ts.bus_stop_key                                         as to_stop_key,

    s.segment_id                                            as segment_id,
    s.direction                                             as direction,
    s.stop_order                                            as stop_order,
    s.day_of_week                                           as day_of_week,
    s.year                                                  as year,
    s.month                                                 as month,
    s.peak_period                                           as peak_period,
    s.is_peak                                               as is_peak,

    s.average_road_speed_mph                                as average_road_speed_mph,
    s.average_travel_time_min                               as average_travel_time_min,
    s.road_distance_mi                                      as road_distance_mi,
    s.bus_trip_count                                        as bus_trip_count

from src s
left join {{ ref('dim_location') }} l on s.grid_cell_id = l.grid_cell_id
left join {{ ref('dim_bus_route') }} r on s.route_id     = r.bus_route_id
left join {{ ref('dim_bus_stop') }}  fs on s.from_stop_id = fs.stop_id
left join {{ ref('dim_bus_stop') }}  ts on s.to_stop_id   = ts.stop_id
