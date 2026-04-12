-- Audit test: reported total_compensation in source should equal
-- (salaries + overtime + other_salaries + total_benefits) within $1.
-- Returns rows where the reconciliation FAILS (test passes if zero rows returned).

select
    fiscal_year,
    employee_name,
    department,
    total_compensation                          as computed_pay,
    total_compensation_reported                 as reported_pay,
    abs(total_compensation_reported
        - (total_compensation + total_benefits)) as variance
from {{ ref('fct_employee_compensation') }}
where abs(total_compensation_reported
    - (total_compensation + total_benefits)) > 1.00
