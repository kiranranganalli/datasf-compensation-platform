{{ config(materialized='view') }}

-- Derives a tenure proxy from the data itself, since the source dataset
-- does not include a hire date. Years of service = count of distinct
-- fiscal years an employee_name appears in the data.
--
-- Caveats (to discuss with data steward):
--  1. Employees who left before 2013 have understated tenure.
--  2. Name collisions (two different people with the same name) inflate tenure.
--     A stable employee_id from the HR system would fix this.

select
    employee_name,
    min(fiscal_year)              as first_year_seen,
    max(fiscal_year)              as latest_year_seen,
    count(distinct fiscal_year)   as years_of_service
from {{ ref('stg_employee_compensation') }}
where employee_name is not null
group by employee_name
