{{ config(materialized='table') }}

with stg as (

    select * from {{ ref('stg_employee_compensation') }}

),

tenure as (

    select
        employee_name as tenure_employee_name,
        first_year_seen,
        latest_year_seen,
        years_of_service
    from {{ ref('int_employee_tenure') }}

),

joined as (

    select
        s.fiscal_year,
        s.year_type,
        s.organization_group,
        s.department,
        s.department_code,
        s.job_family,
        s.job_title,
        s.job_code,
        s.union_code,
        s.union_name,
        s.employee_name,
        s.employment_type,
        s.salaries,
        s.overtime,
        s.other_salaries,
        (s.salaries + s.overtime + s.other_salaries) as total_compensation,
        s.retirement,
        s.health_and_dental,
        s.other_benefits,
        s.total_benefits,
        s.total_compensation_reported,
        s.hours,
        t.years_of_service,
        s.source_data_as_of,
        s.dbt_loaded_at
    from stg s
    left join tenure t
        on s.employee_name = t.tenure_employee_name

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'fiscal_year', 'year_type', 'employee_name',
            'job_code', 'department_code', 'union_code'
        ]) }} as compensation_pk,

        fiscal_year,
        year_type,
        organization_group,
        department,
        job_family,
        job_title,
        union_name,
        employee_name,
        employment_type,

        salaries,
        overtime,
        other_salaries,
        total_compensation,

        retirement,
        health_and_dental,
        other_benefits,
        total_benefits,
        total_compensation_reported,
        hours,

        years_of_service,
        case
            when years_of_service is null then 'Unknown'
            when years_of_service < 2     then '0-1 years'
            when years_of_service < 5     then '2-4 years'
            when years_of_service < 10    then '5-9 years'
            when years_of_service < 20    then '10-19 years'
            else                               '20+ years'
        end as tenure_bracket,

        source_data_as_of,
        dbt_loaded_at

    from joined

)

select * from final
