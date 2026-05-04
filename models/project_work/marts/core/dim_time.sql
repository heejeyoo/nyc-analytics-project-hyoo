{{ config(materialized='table') }}

-- Hour-of-day dimension. 24 rows.

with hours as (
    select hr from unnest(generate_array(0, 23)) as hr
)

select
    hr                                          as time_key,
    hr                                          as hour,
    case when hr < 12 then 'AM' else 'PM' end   as am_pm,
    {{ peak_period('hr') }}                     as peak_period,
    {{ is_peak('hr') }}                         as is_peak
from hours
