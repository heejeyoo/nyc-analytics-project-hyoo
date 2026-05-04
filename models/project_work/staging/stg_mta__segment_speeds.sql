{{ config(materialized='view') }}

-- Staging: MTA Bus Route Segment Speeds.
-- Grain: route × segment (timepoint A → timepoint B) × direction × hour_of_day × day_of_week × month × year.

with src as (
    select * from {{ source('nyc_proj2_raw_data', 'source_MTA_Bus_Route_Segment') }}
),

typed as (
    select
        cast(route_id as string)                                                as route_id,
        cast(route_type as string)                                              as route_type,
        cast(direction as string)                                               as direction,
        cast(stop_order as int64)                                               as stop_order,

        cast(timepoint_stop_id as string)                                       as from_stop_id,
        cast(timepoint_stop_name as string)                                     as from_stop_name,
        safe_cast(timepoint_stop_latitude  as float64)                          as from_stop_latitude,
        safe_cast(timepoint_stop_longitude as float64)                          as from_stop_longitude,

        cast(next_timepoint_stop_id as string)                                  as to_stop_id,
        cast(next_timepoint_stop_name as string)                                as to_stop_name,
        safe_cast(next_timepoint_stop_latitude  as float64)                     as to_stop_latitude,
        safe_cast(next_timepoint_stop_longitude as float64)                     as to_stop_longitude,

        cast(borough as string)                                                 as borough_reported,
        cast(year as int64)                                                     as year,
        cast(month as int64)                                                    as month,
        cast(day_of_week as string)                                             as day_of_week,
        cast(hour_of_day as int64)                                              as hour_of_day,
        cast(timestamp as timestamp)                                            as observation_timestamp,

        safe_cast(average_road_speed  as float64)                               as average_road_speed_mph,
        safe_cast(average_travel_time as float64)                               as average_travel_time_min,
        safe_cast(road_distance       as float64)                               as road_distance_mi,
        safe_cast(bus_trip_count      as int64)                                 as bus_trip_count
    from src
)

select *
from typed
where from_stop_latitude is not null and from_stop_longitude is not null
  and to_stop_latitude   is not null and to_stop_longitude   is not null
  and average_road_speed_mph is not null
