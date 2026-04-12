terraform {
  required_version = ">= 1.5.0"

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.95"
    }
  }
}

# Authentication is read from environment variables, never hardcoded:
#   SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PASSWORD, SNOWFLAKE_ROLE
# In CI/CD, these are injected from GitHub Secrets / AWS Secrets Manager.
provider "snowflake" {
  role = "ACCOUNTADMIN"
}
