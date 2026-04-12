# ============================================================================
# SECURITY POLICIES MODULE
# Dynamic data masking + row access policy for the fact table.
# ============================================================================

# --- Masking policy on employee_name ---
# Handles both numeric IDs (current source format) and plain text names
# (defensive design — no hotfix needed if source format changes)
resource "snowflake_masking_policy" "employee_name_mask" {
  name     = "EMPLOYEE_NAME_MASK"
  database = var.database_name
  schema   = var.schema_name
  signature {
    column {
      name = "val"
      type = "STRING"
    }
  }
  return_data_type = "STRING"
  body             = <<-SQL
    case
      when current_role() in ('ACCOUNTADMIN', 'AUDITOR') then val
      when current_role() = 'HR_ANALYST' then
        case
          when val rlike '^[0-9]+$' then concat('ID-****', right(val, 3))
          else regexp_replace(val, '([A-Za-z])[A-Za-z]+', '\\1***')
        end
      else '***REDACTED***'
    end
  SQL
}

# --- Row access policy ---
# Enumerates every legitimate role explicitly. PUBLIC_ACCESS is included
# because the agg view depends on the underlying fact table — without it,
# the view returns zero rows. (See task2_writeup.md for the full story.)
resource "snowflake_row_access_policy" "auditor_dept_filter" {
  name     = "AUDITOR_DEPT_FILTER"
  database = var.database_name
  schema   = var.schema_name
  signature {
    column {
      name = "department"
      type = "STRING"
    }
  }
  row_access_expression = <<-SQL
    case
      when current_role() = 'ACCOUNTADMIN'  then true
      when current_role() = 'HR_ANALYST'    then true
      when current_role() = 'PUBLIC_ACCESS' then true
      when current_role() = 'AUDITOR'
        then ${join(" or ", [for d in var.allowed_departments : "department ilike '%${d}%'"])}
      else false
    end
  SQL
}

# Attach the masking policy to the column
resource "snowflake_table_column_masking_policy_application" "employee_name_mask_apply" {
  table          = "${var.database_name}.${var.schema_name}.${var.fact_table_name}"
  column         = "EMPLOYEE_NAME"
  masking_policy = "${snowflake_masking_policy.employee_name_mask.database}.${snowflake_masking_policy.employee_name_mask.schema}.${snowflake_masking_policy.employee_name_mask.name}"
}

# Attach the row access policy to the table
resource "snowflake_table_row_access_policy" "auditor_dept_apply" {
  table_name        = "${var.database_name}.${var.schema_name}.${var.fact_table_name}"
  row_access_policy = "${snowflake_row_access_policy.auditor_dept_filter.database}.${snowflake_row_access_policy.auditor_dept_filter.schema}.${snowflake_row_access_policy.auditor_dept_filter.name}"
  on                = ["DEPARTMENT"]
}
