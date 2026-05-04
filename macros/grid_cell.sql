{# ============================================================
   grid_cell_id(longitude, latitude)
   ------------------------------------------------------------
   Buckets a lat/lon into a discrete spatial cell using BigQuery's
   native ST_SNAPTOGRID. All three facts use this macro so they
   share a join key (grid_cell_id) without needing H3 UDFs.

   Cell size is configured in dbt_project.yml (vars.grid_size_deg).
   Default 0.0015 deg ≈ 150m at NYC latitude.
   ============================================================ #}

{% macro grid_cell_id(longitude_col, latitude_col) %}
    ST_ASTEXT(
      ST_SNAPTOGRID(
        ST_GEOGPOINT({{ longitude_col }}, {{ latitude_col }}),
        {{ var('grid_size_deg') }}
      )
    )
{% endmacro %}


{# Grid centroid lat/lon — useful for Dim_Location attributes. #}
{% macro grid_cell_centroid_lon(longitude_col) %}
    ROUND({{ longitude_col }} / {{ var('grid_size_deg') }}) * {{ var('grid_size_deg') }}
{% endmacro %}

{% macro grid_cell_centroid_lat(latitude_col) %}
    ROUND({{ latitude_col }} / {{ var('grid_size_deg') }}) * {{ var('grid_size_deg') }}
{% endmacro %}
