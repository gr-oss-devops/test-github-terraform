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
  repos = {
    for file in local.repo_configs :
    trimsuffix(basename(file), replace(basename(file), "^(.*?)(\\.ya?ml)?$", "$2")) => yamldecode(file(file))
  }
}

resource "github_repository" "repos" {
  for_each = local.repos

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility

  auto_init = true

  topics = each.value.topics

  has_issues    = each.value.has_issues
  has_projects  = each.value.has_projects
  has_wiki      = each.value.has_wiki
  has_downloads = each.value.has_downloads
}

resource "github_branch_protection" "main" {
  for_each = local.repos

  repository_id = github_repository.repos[each.key].node_id
  pattern       = "main"

  required_status_checks {
    strict   = true
    contexts = ["ci/github-actions"]
  }

  required_pull_request_reviews {
    dismiss_stale_reviews      = true
    require_code_owner_reviews = true
  }
}