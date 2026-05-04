{{ config(materialized='table') }}

-- Fact: 311 curb-relevant complaints.
-- Grain: one row per 311 complaint event.

with src as (
    select * from {{ ref('int_311__with_geo') }}
),

stops as (
    select bus_stop_key, stop_id, bus_stop_latitude, bus_stop_longitude
    from {{ ref('dim_bus_stop') }}
),

-- Nearest stop assignment via ST_DISTANCE; threshold 100m to keep noise out
nearest_stop as (
    select
        s.unique_key,
        st.bus_stop_key,
        st_distance(
            st_geogpoint(s.longitude,        s.latitude),
            st_geogpoint(st.bus_stop_longitude, st.bus_stop_latitude)
        )                                                      as distance_m
    from src s
    cross join stops st
    qualify row_number() over (partition by s.unique_key order by distance_m asc) = 1
),

nearest_filtered as (
    select unique_key, bus_stop_key, distance_m
    from nearest_stop
    where distance_m <= 100.0
),

joined as (
    select
        farm_fingerprint(s.unique_key)                          as complaint_key,
        s.unique_key                                            as nat_unique_key,
        cast(format_date('%Y%m%d', s.event_date) as int64)      as date_key,
        s.event_hour                                            as time_key,
        l.location_key                                          as location_key,
        p.problem_key                                           as problem_key,
        nf.bus_stop_key                                         as nearest_bus_stop_key,
        nf.distance_m                                           as nearest_bus_stop_distance_m,
        s.latitude,
        s.longitude,
        s.status,
        s.created_date,
        s.closed_date,
        s.peak_period,
        s.is_peak,
        s.problem_category,
        1                                                       as complaint_count
    from src s
    left join {{ ref('dim_location') }} l
        on s.grid_cell_id = l.grid_cell_id
    left join {{ ref('dim_311_problem') }} p
        on  coalesce(s.agency,'')          = coalesce(p.agency,'')
        and coalesce(s.complaint_type,'')  = coalesce(p.complaint_type,'')
        and coalesce(s.descriptor,'')      = coalesce(p.problem_detail,'')
    left join nearest_filtered nf
        on s.unique_key = nf.unique_key
)

select * from joined
