# ============================================================================
# DATASF EMPLOYEE COMPENSATION — Top-level Terraform composition
# ============================================================================
# This file wires together the modules. Each module is self-contained and
# reusable across environments via tfvars files.

module "roles" {
  source         = "./modules/roles"
  database_name  = var.database_name
  warehouse_name = "COMPUTE_WH"
}

module "security_policies" {
  source              = "./modules/security_policies"
  database_name       = var.database_name
  schema_name         = "RAW"
  fact_table_name     = "FCT_EMPLOYEE_COMPENSATION"
  allowed_departments = var.auditor_allowed_departments

  # Explicit dependency: roles must exist before policies reference them
  depends_on = [module.roles]
}
