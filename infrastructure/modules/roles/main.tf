# ============================================================================
# ROLES MODULE
# Three Snowflake roles balancing data democratization with privacy.
# ============================================================================

resource "snowflake_role" "public_access" {
  name    = "PUBLIC_ACCESS"
  comment = "Civic transparency role: aggregated, k-anonymized data only."
}

resource "snowflake_role" "hr_analyst" {
  name    = "HR_ANALYST"
  comment = "HR analytics role: full row-level access with PII masked."
}

resource "snowflake_role" "auditor" {
  name    = "AUDITOR"
  comment = "Audit role: full unmasked access, restricted by RLS to specific departments."
}

# Warehouse usage — every role needs at least USAGE to run a query
resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  for_each          = toset([
    snowflake_role.public_access.name,
    snowflake_role.hr_analyst.name,
    snowflake_role.auditor.name,
  ])
  account_role_name = each.value
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.warehouse_name
  }
}

# Database & schema usage — minimum to navigate to the objects
resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  for_each          = toset([
    snowflake_role.public_access.name,
    snowflake_role.hr_analyst.name,
    snowflake_role.auditor.name,
  ])
  account_role_name = each.value
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = var.database_name
  }
}

# Object-level grants — least privilege per role
# PUBLIC_ACCESS: only the public agg view
resource "snowflake_grant_privileges_to_account_role" "public_access_agg" {
  account_role_name = snowflake_role.public_access.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "VIEW"
    object_name = "${var.database_name}.RAW.AGG_COMPENSATION_BY_JOB_FAMILY"
  }
}

# HR_ANALYST: row-level fact (will be masked) + agg view
resource "snowflake_grant_privileges_to_account_role" "hr_analyst_fact" {
  account_role_name = snowflake_role.hr_analyst.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "TABLE"
    object_name = "${var.database_name}.RAW.FCT_EMPLOYEE_COMPENSATION"
  }
}

# AUDITOR: row-level fact (will be RLS-filtered)
resource "snowflake_grant_privileges_to_account_role" "auditor_fact" {
  account_role_name = snowflake_role.auditor.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "TABLE"
    object_name = "${var.database_name}.RAW.FCT_EMPLOYEE_COMPENSATION"
  }
}
