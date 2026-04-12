{{ config(materialized='view') }}

with source as (

    -- Distinct removes only true full-row duplicates (safer than partial-key dedup,
    -- which could collapse legitimate multi-position records for the same employee).
    select distinct * from {{ source('raw', 'employee_compensation') }}

),

cleaned as (

    select
        -- Identifiers & dimensions
        cast(replace(year, ',', '') as integer)            as fiscal_year,
        upper(trim(year_type))                             as year_type,
        trim(organization_group_code)                      as organization_group_code,
        initcap(trim(organization_group))                  as organization_group,
        trim(department_code)                              as department_code,
        initcap(trim(department))                          as department,
        trim(union_code)                                   as union_code,
        initcap(trim(union_name))                          as union_name,
        trim(job_family_code)                              as job_family_code,
        initcap(trim(job_family))                          as job_family,
        trim(job_code)                                     as job_code,
        initcap(trim(job))                                 as job_title,
        trim(employee_name)                                as employee_name,
        trim(employment_type)                              as employment_type,

        -- Financial columns: strip commas, then cast
        cast(replace(coalesce(salaries, '0'), ',', '') as number(14,2))             as salaries,
        cast(replace(coalesce(overtime, '0'), ',', '') as number(14,2))             as overtime,
        cast(replace(coalesce(other_salaries, '0'), ',', '') as number(14,2))       as other_salaries,
        cast(replace(coalesce(total_salary, '0'), ',', '') as number(14,2))         as total_salary_reported,
        cast(replace(coalesce(retirement, '0'), ',', '') as number(14,2))           as retirement,
        cast(replace(coalesce(health_and_dental, '0'), ',', '') as number(14,2))    as health_and_dental,
        cast(replace(coalesce(other_benefits, '0'), ',', '') as number(14,2))       as other_benefits,
        cast(replace(coalesce(total_benefits, '0'), ',', '') as number(14,2))       as total_benefits,
        cast(replace(coalesce(total_compensation, '0'), ',', '') as number(14,2))   as total_compensation_reported,
        cast(replace(coalesce(hours, '0'), ',', '') as number(12,2))                as hours,

        -- Metadata
        try_cast(data_as_of as timestamp_ntz)              as source_data_as_of,
        try_cast(data_loaded_at as timestamp_ntz)          as source_loaded_at,
        current_timestamp()                                as dbt_loaded_at

    from source

)

select * from cleaned
