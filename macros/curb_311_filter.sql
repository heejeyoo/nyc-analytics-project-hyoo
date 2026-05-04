{# Centralized definition of "curb-relevant" 311 complaint types.
   Filter list is configured in dbt_project.yml (vars.curb_311_complaint_types). #}

{% macro is_curb_311(complaint_type_col) %}
    UPPER({{ complaint_type_col }}) IN (
      {%- for c in var('curb_311_complaint_types') -%}
        '{{ c | upper }}'{% if not loop.last %}, {% endif %}
      {%- endfor -%}
    )
{% endmacro %}


{# Curated 311 problem-category bucket used by Dim_311_Problem.
   Drives KPI filters (e.g., double-parking only, blocked-bus-stop only). #}
{% macro problem_category(complaint_type_col, descriptor_col) %}
    CASE
      WHEN UPPER({{ descriptor_col }}) LIKE '%BUS STOP%'              THEN 'blocked_bus_stop'
      WHEN UPPER({{ descriptor_col }}) LIKE '%HYDRANT%'               THEN 'blocked_hydrant'
      WHEN UPPER({{ descriptor_col }}) LIKE '%DOUBLE PARK%'           THEN 'double_parking'
      WHEN UPPER({{ descriptor_col }}) LIKE '%DRIVEWAY%'              THEN 'blocked_driveway'
      WHEN UPPER({{ complaint_type_col }}) LIKE '%ILLEGAL PARKING%'   THEN 'illegal_parking'
      WHEN UPPER({{ complaint_type_col }}) LIKE '%TRAFFIC%'           THEN 'other_traffic'
      ELSE 'other'
    END
{% endmacro %}
