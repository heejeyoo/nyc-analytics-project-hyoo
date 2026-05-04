{{ config(materialized='table') }}

-- Date spine covering observed dates across all three facts (with a small buffer).

with bounds as (
    select
        least(
            (select min(event_date) from {{ ref('int_311__with_geo') }}),
            (select min(event_date) from {{ ref('int_ace__with_geo') }}),
            (select date(min(observation_timestamp)) from {{ ref('int_segment__with_geo') }})
        )                       as min_date,
        greatest(
            (select max(event_date) from {{ ref('int_311__with_geo') }}),
            (select max(event_date) from {{ ref('int_ace__with_geo') }}),
            (select date(max(observation_timestamp)) from {{ ref('int_segment__with_geo') }})
        )                       as max_date
),

date_spine as (
    select day as full_date
    from bounds, unnest(generate_date_array(min_date, max_date)) as day
)

select
    cast(format_date('%Y%m%d', full_date) as int64)         as date_key,
    full_date,
    extract(year    from full_date)                         as year,
    extract(quarter from full_date)                         as quarter,
    extract(month   from full_date)                         as month,
    extract(day     from full_date)                         as day,
    format_date('%A', full_date)                            as day_of_week,
    case when extract(dayofweek from full_date) in (1, 7) then true else false end as is_weekend
from date_spine
