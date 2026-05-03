select
  unique_key,
  created_date,
  complaint_type,
  borough
from {{ source('raw', 'source_dot_service_requests_history') }}