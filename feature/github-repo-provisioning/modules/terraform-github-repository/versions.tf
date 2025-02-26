# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM AND PROVIDER REQUIREMENTS FOR RUNNING THIS MODULE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = "~> 1.0"

  # branch_protections_v3 are broken in >= 5.3
  required_providers {
    github = {
#      source  = "integrations/github"
      source = "app.terraform.io/GR-OSS/github"
#      version = ">= 4.20, < 6.0"
      version = "6.5.0"
    }
  }
}
