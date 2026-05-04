{{ config(materialized='table') }}

-- Conformed Location dimension keyed on grid_cell_id.
-- Built as the UNION of all grid cells appearing in any of the three facts,
-- so every fact row resolves to a Dim_Location row.
--
-- Borough is inferred per-cell using majority vote across observations.

with cells_311 as (
    select
        grid_cell_id,
        grid_lat,
        grid_lon,
        upper(borough_reported)                             as borough_observed,
        zip_reported                                        as zip_observed,
        cast(council_district_reported as string)           as council_observed
    from {{ ref('int_311__with_geo') }}
    where grid_cell_id is not null
),

cells_ace as (
    select
        grid_cell_id,
        grid_lat,
        grid_lon,
        upper(borough_from_route)                           as borough_observed,
        cast(null as string)                                as zip_observed,
        cast(null as string)                                as council_observed
    from {{ ref('int_ace__with_geo') }}
    where grid_cell_id is not null
),

cells_seg as (
    select
        grid_cell_id,
        grid_lat,
        grid_lon,
        upper(borough_reported)                             as borough_observed,
        cast(null as string)                                as zip_observed,
        cast(null as string)                                as council_observed
    from {{ ref('int_segment__with_geo') }}
    where grid_cell_id is not null
),

unioned as (
    select * from cells_311
    union all select * from cells_ace
    union all select * from cells_seg
),

borough_votes as (
    select
        grid_cell_id,
        borough_observed,
        count(*) as votes
    from unioned
    where borough_observed is not null
    group by grid_cell_id, borough_observed
),

borough_winner as (
    select grid_cell_id, borough_observed as borough
    from borough_votes
    qualify row_number() over (partition by grid_cell_id order by votes desc) = 1
),

zip_winner as (
    select
        grid_cell_id,
        any_value(zip_observed)         as zip_code,
        any_value(council_observed)     as council_district
    from unioned
    where zip_observed is not null
    group by grid_cell_id
),

cells as (
    select
        grid_cell_id,
        avg(grid_lat)                   as grid_lat,
        avg(grid_lon)                   as grid_lon
    from unioned
    where grid_cell_id is not null
    group by grid_cell_id
)

select
    farm_fingerprint(c.grid_cell_id)        as location_key,
    c.grid_cell_id,
    c.grid_lat,
    c.grid_lon,
    initcap(b.borough)                      as borough,
    z.zip_code,
    z.council_district
from cells c
left join borough_winner b using (grid_cell_id)
left join zip_winner     z using (grid_cell_id)