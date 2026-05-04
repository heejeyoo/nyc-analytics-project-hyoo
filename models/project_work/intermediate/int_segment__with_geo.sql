{{ config(materialized='table') }}

-- Segment performance enriched with grid_cell_id (segment midpoint),
-- a synthetic segment_id, and peak-period flag.

with src as (
    select * from {{ ref('stg_mta__segment_speeds') }}
),

enriched as (
    select
        src.*,

        -- Segment natural key: route + ordered stop pair + direction
        concat(
            route_id, '|',
            from_stop_id, '->', to_stop_id, '|',
            coalesce(direction, '?')
        )                                                                       as segment_id,

        -- Midpoint of segment, used for spatial joining to other facts
        (from_stop_latitude  + to_stop_latitude)  / 2                           as midpoint_latitude,
        (from_stop_longitude + to_stop_longitude) / 2                           as midpoint_longitude,
        {{ grid_cell_id(
            '(from_stop_longitude + to_stop_longitude) / 2',
            '(from_stop_latitude  + to_stop_latitude)  / 2'
        ) }}                                                                    as grid_cell_id,
        {{ grid_cell_centroid_lat('(from_stop_latitude + to_stop_latitude) / 2') }}   as grid_lat,
        {{ grid_cell_centroid_lon('(from_stop_longitude + to_stop_longitude) / 2') }} as grid_lon,

        {{ peak_period('hour_of_day') }}                                        as peak_period,
        {{ is_peak('hour_of_day') }}                                            as is_peak

    from src
)

select * from enriched
