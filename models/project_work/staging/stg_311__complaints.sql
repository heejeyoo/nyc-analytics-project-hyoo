{{ config(materialized='view') }}

-- Staging: NYC 311 service requests, restricted to curb-relevant complaint types.
-- Deduped to one row per unique_key (most recent created_date wins).

with src as (
    select * from {{ source('nyc_proj2_raw_data', 'source_nyc_311_traffic') }}
),

typed as (
    select
        cast(unique_key as string)                                              as unique_key,
        cast(created_date as timestamp)                                         as created_date,
        cast(closed_date as timestamp)                                          as closed_date,
        cast(resolution_action_updated_date as timestamp)                       as resolution_updated_date,
        cast(agency as string)                                                  as agency,
        cast(agency_name as string)                                             as agency_name,
        cast(complaint_type as string)                                          as complaint_type,
        cast(descriptor as string)                                              as descriptor,
        cast(status as string)                                                  as status,
        cast(borough as string)                                                 as borough_reported,
        cast(incident_zip as string)                                            as zip_reported,
        cast(council_district as int64)                                         as council_district_reported,
        safe_cast(latitude  as float64)                                         as latitude,
        safe_cast(longitude as float64)                                         as longitude,
        cast(incident_address as string)                                        as incident_address,
        cast(street_name as string)                                             as street_name,
        cast(landmark as string)                                                as landmark,
        cast(location_type as string)                                           as location_type,
        cast(resolution_description as string)                                  as resolution_description
    from src
),

filtered as (
    select *
    from typed
    where {{ is_curb_311('complaint_type') }}
      and latitude  is not null
      and longitude is not null
      and unique_key is not null
)

select *
from filtered
qualify row_number() over (
    partition by unique_key
    order by created_date desc, resolution_updated_date desc
) = 1