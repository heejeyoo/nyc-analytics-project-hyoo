{{ config(materialized='table') }}

-- ============================================================================
-- dim_date
-- ----------------------------------------------------------------------------
-- Conformed date/time dimension. Shared by both fact tables.
--
-- Built by generating one row per HOUR over an 8-year window (2019-01-01
-- through 2026-12-31). Grain is hour because peak-hour analysis is one of
-- our headline questions. The window is sized to comfortably cover the
-- actual date ranges in both source tables (311: 2020-2026, ACE: 2019-2026).
--
-- date_key is an integer in YYYYMMDDHH form (e.g. 2025031408 = March 14,
-- 2025 at 8 AM). Easy to read, easy to join, no surrogate key generation
-- needed.
-- ============================================================================

with hours as (

    -- generate one timestamp per hour across the analysis window
    select
        timestamp_add(
            timestamp('2019-01-01 00:00:00'),
            interval n hour
        ) as full_datetime
    from unnest(
        generate_array(0, 24 * 365 * 8)   -- 8 years of hours
    ) as n

)

select
    -- primary key: integer YYYYMMDDHH (e.g. 2025031408)
    cast(format_timestamp('%Y%m%d%H', full_datetime) as int64) as date_key,

    full_datetime,
    extract(year       from full_datetime) as year,
    extract(month      from full_datetime) as month,
    extract(day        from full_datetime) as day,
    extract(hour       from full_datetime) as hour,
    format_timestamp('%A', full_datetime)  as day_of_week,

    -- helpful derived attributes for KPI marts
    case
        when extract(dayofweek from full_datetime) in (1, 7) then 'Weekend'
        else 'Weekday'
    end as weekday_or_weekend,

    case
        when extract(hour from full_datetime) between  7 and  9 then 'AM_PEAK'
        when extract(hour from full_datetime) between 10 and 15 then 'MIDDAY'
        when extract(hour from full_datetime) between 16 and 19 then 'PM_PEAK'
        when extract(hour from full_datetime) between 20 and 23 then 'EVENING'
        else 'OVERNIGHT'
    end as peak_period

from hours
