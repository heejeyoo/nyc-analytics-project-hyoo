{{ config(materialized='table') }}

-- HEADLINE OUTPUT — KPI #8: Top-25 Pilot Candidates.
-- Ranked list with component breakdown and enforcement-gap flag.

with si as (
    select * from {{ ref('mart_squeeze_index') }}
),

gap as (
    select
        location_key,
        sum(complaints_311)         as total_311,
        sum(citations_issued)       as total_citations,
        safe_divide(
            sum(complaints_311),
            nullif(sum(citations_issued), 0)
        )                           as enforcement_gap_index
    from {{ ref('mart_enforcement_gap_by_segment_month') }}
    group by location_key
),

ranked as (
    select
        si.*,
        g.total_311,
        g.total_citations,
        g.enforcement_gap_index,
        case
            when g.enforcement_gap_index > 2.0 and si.conflict_density > 0
            then true else false
        end as is_enforcement_dark_spot,
        row_number() over (order by si.squeeze_index desc) as rank
    from si
    left join gap g using (location_key)
)

select
    rank,
    location_key,
    grid_cell_id,
    borough,
    zip_code,
    council_district,
    round(squeeze_index,    4)      as squeeze_index,
    round(peak_norm,        4)      as peak_component,
    round(conflict_norm,    4)      as conflict_component,
    round(ridership_norm,   4)      as ridership_component,
    round(peak_speed_penalty, 4)    as peak_speed_penalty_raw,
    round(conflict_density,   4)    as conflict_density_raw,
    round(ridership_weighted_delay_min, 1) as ridership_weighted_delay_min,
    total_311,
    total_citations,
    round(enforcement_gap_index, 2) as enforcement_gap_index,
    is_enforcement_dark_spot
from ranked
where rank <= 25
order by rank
