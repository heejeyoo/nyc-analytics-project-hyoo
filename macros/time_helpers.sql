{# Peak-period classification used in Dim_Time and segment performance KPIs. #}

{% macro peak_period(hour_col) %}
    CASE
      WHEN {{ hour_col }} >= {{ var('am_peak_start') }}
       AND {{ hour_col }} <  {{ var('am_peak_end') }}   THEN 'AM_PEAK'
      WHEN {{ hour_col }} >= {{ var('pm_peak_start') }}
       AND {{ hour_col }} <  {{ var('pm_peak_end') }}   THEN 'PM_PEAK'
      WHEN {{ hour_col }} BETWEEN 10 AND 15             THEN 'MIDDAY'
      WHEN {{ hour_col }} BETWEEN 20 AND 23             THEN 'EVENING'
      ELSE 'OVERNIGHT'
    END
{% endmacro %}

{% macro is_peak(hour_col) %}
    (
      ({{ hour_col }} >= {{ var('am_peak_start') }} AND {{ hour_col }} < {{ var('am_peak_end') }})
      OR
      ({{ hour_col }} >= {{ var('pm_peak_start') }} AND {{ hour_col }} < {{ var('pm_peak_end') }})
    )
{% endmacro %}


{# Borough inference from MTA bus_route_id prefix.
   Used as a FALLBACK for ACE rows whose lat/lon spatial join returns NULL.
   NEVER used as the primary borough source. #}
{% macro borough_from_route_prefix(route_col) %}
    CASE
      WHEN STARTS_WITH(UPPER({{ route_col }}), 'BXM') THEN 'Bronx'
      WHEN STARTS_WITH(UPPER({{ route_col }}), 'BM')  THEN 'Brooklyn'
      WHEN STARTS_WITH(UPPER({{ route_col }}), 'BX')  THEN 'Bronx'
      WHEN STARTS_WITH(UPPER({{ route_col }}), 'QM')  THEN 'Queens'
      WHEN STARTS_WITH(UPPER({{ route_col }}), 'SIM') THEN 'Staten Island'
      WHEN STARTS_WITH(UPPER({{ route_col }}), 'B')   THEN 'Brooklyn'
      WHEN STARTS_WITH(UPPER({{ route_col }}), 'M')   THEN 'Manhattan'
      WHEN STARTS_WITH(UPPER({{ route_col }}), 'Q')   THEN 'Queens'
      WHEN STARTS_WITH(UPPER({{ route_col }}), 'S')   THEN 'Staten Island'
      WHEN STARTS_WITH(UPPER({{ route_col }}), 'X')   THEN 'Manhattan'
      ELSE NULL
    END
{% endmacro %}
