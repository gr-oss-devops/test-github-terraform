provider "github" {}

locals {
  repo_configs = fileset(path.module, "repo_configs/*.{yml,yaml}")
}

data "local_file" "repo_file" {
  for_each = toset(local.repo_configs)
  filename = each.value
}

locals {
  repos = {
    for file_path, file_data in data.local_file.repo_file :
    split(".", basename(file_path))[0] => yamldecode(file_data.content)
  }
}

module "repository" {
  source    = "mineiros-io/repository/github"
  version   = "~> 0.18.0"
  for_each  = local.repos
  name      = each.key
}