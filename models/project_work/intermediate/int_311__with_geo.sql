{{ config(materialized='table') }}

-- 311 complaints enriched with grid_cell_id, problem_category, and a derived event_hour.

with src as (
    select * from {{ ref('stg_311__complaints') }}
)

select
    src.*,
    {{ grid_cell_id('longitude', 'latitude') }}             as grid_cell_id,
    {{ grid_cell_centroid_lat('latitude') }}                as grid_lat,
    {{ grid_cell_centroid_lon('longitude') }}               as grid_lon,
    extract(date from created_date)                         as event_date,
    extract(hour from created_date)                         as event_hour,
    {{ peak_period('extract(hour from created_date)') }}    as peak_period,
    {{ is_peak('extract(hour from created_date)') }}        as is_peak,
    {{ problem_category('complaint_type', 'descriptor') }}  as problem_category
from src
