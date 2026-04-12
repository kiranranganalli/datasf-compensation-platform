output "role_names" {
  value = {
    public_access = snowflake_role.public_access.name
    hr_analyst    = snowflake_role.hr_analyst.name
    auditor       = snowflake_role.auditor.name
  }
}
