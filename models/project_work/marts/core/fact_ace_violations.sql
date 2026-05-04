{{ config(materialized='table') }}

-- Fact: MTA ACE violations.
-- Grain: one row per ACE violation event.

with src as (
    select * from {{ ref('int_ace__with_geo') }}
)

select
    farm_fingerprint(s.violation_id)                            as violation_key,
    s.violation_id                                              as nat_violation_id,
    cast(format_date('%Y%m%d', s.event_date) as int64)          as date_key,
    s.event_hour                                                as time_key,
    l.location_key                                              as location_key,
    vt.violation_type_key                                       as violation_type_key,
    st_dim.ace_status_key                                       as ace_status_key,
    r.route_key                                                 as route_key,
    bs.bus_stop_key                                             as bus_stop_key,
    s.violation_latitude,
    s.violation_longitude,
    s.first_occurrence,
    s.last_occurrence,
    s.peak_period,
    s.is_peak,
    s.citation_issued,
    1                                                           as violation_count,
    case when s.citation_issued then 1 else 0 end               as citation_issued_count
from src s
left join {{ ref('dim_location') }}            l       on s.grid_cell_id = l.grid_cell_id
left join {{ ref('dim_ace_violation_type') }}  vt      on s.violation_type = vt.violation_category
left join {{ ref('dim_ace_status') }}          st_dim  on s.violation_status = st_dim.violation_status
                                                       and s.citation_issued = st_dim.citation_issued
left join {{ ref('dim_bus_route') }}           r       on s.bus_route_id = r.bus_route_id
left join {{ ref('dim_bus_stop') }}            bs      on s.stop_id = bs.stop_id
