{{ config(materialized='view') }}

-- Public-facing aggregate, designed for the PUBLIC_ACCESS role.
-- Suppresses small groups (k-anonymity, k=5) to mitigate re-identification risk.

select
    fiscal_year,
    organization_group,
    job_family,
    count(distinct employee_name)         as employee_count,
    sum(total_compensation)               as total_pay,
    avg(total_compensation)               as avg_pay,
    median(total_compensation)            as median_pay,
    min(total_compensation)               as min_pay,
    max(total_compensation)               as max_pay
from {{ ref('fct_employee_compensation') }}
group by 1, 2, 3
having count(distinct employee_name) >= 5
