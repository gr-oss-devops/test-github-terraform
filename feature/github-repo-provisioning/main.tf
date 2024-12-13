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

import {
  for_each = local.repos
  to = module.repository[each.key].github_repository.repository
  id = each.key
}

module "repository" {
  source                  = "mineiros-io/repository/github"
  version                 = "~> 0.18.0"
  for_each                = local.repos

  name                    = each.key
  description             = try(each.value.description, null)
  visibility              = try(each.value.visibility, "private")
  auto_init               = try(each.value.auto_init, true)
  topics                  = try(each.value.topics, [])
  has_issues              = try(each.value.has_issues, true)
  has_projects            = try(each.value.has_projects, true)
  has_wiki                = try(each.value.has_wiki, true)
  has_downloads           = try(each.value.has_downloads, true)

  archive_on_destroy      = try(each.value.archive_on_destroy, false)
  issue_labels_create     = false

  homepage_url            = try(each.value.homepage_url, null)
  allow_merge_commit      = try(each.value.allow_merge_commit, null)
  allow_rebase_merge      = try(each.value.allow_rebase_merge, null)
  allow_squash_merge      = try(each.value.allow_squash_merge, null)
  allow_auto_merge        = try(each.value.allow_auto_merge, null)
  delete_branch_on_merge  = try(each.value.delete_branch_on_merge, null)
  is_template             = try(each.value.is_template, null)
  archived                = try(each.value.archived, false)
  vulnerability_alerts    = try(each.value.vulnerability_alerts, null)

  default_branch          = try(each.value.default_branch, null)
}