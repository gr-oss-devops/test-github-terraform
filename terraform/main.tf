terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

locals {
  repo_configs = fileset(path.module, "repo_configs/*.{yml,yaml}")
  decoded_yaml_files = {
    for k, v in data.local_file.repo_file : k => yamldecode(v.content)
  }
}

data "local_file" "repo_file" {
  for_each = local.repo_configs
  filename = each.key
}