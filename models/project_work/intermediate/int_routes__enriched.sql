{{ config(materialized='table') }}

-- Route dimension input: union of routes appearing in ACE and Segment data.
-- ACE coverage = route appears in ACE data (proxy for has_ace_camera).

with ace_routes as (
    select distinct
        bus_route_id as route_id
    from {{ ref('int_ace__with_geo') }}
    where bus_route_id is not null
      and trim(bus_route_id) != ''
),

seg_routes as (
    select
        route_id,
        any_value(route_type) as route_type
    from {{ ref('int_segment__with_geo') }}
    where route_id is not null
      and trim(route_id) != ''
    group by route_id
),

unioned as (
    select route_id from ace_routes
    union distinct
    select route_id from seg_routes
),

enriched as (
    select
        u.route_id                                          as bus_route_id,
        seg.route_type                                      as route_type,
        case when ace.route_id is not null then true else false end as has_ace_camera,
        {{ borough_from_route_prefix('u.route_id') }}       as primary_borough_from_prefix,
        case
            when regexp_contains(upper(u.route_id), r'\+$') or upper(seg.route_type) = 'SBS'
            then true else false
        end                                                 as is_sbs,
        'MTA'                                               as agency_name
    from unioned u
    left join seg_routes seg using (route_id)
    left join ace_routes ace using (route_id)
)

select * from enriched
where bus_route_id is not null