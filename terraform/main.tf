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
    lower(replace(trimsuffix(basename(file), replace(basename(file), "^(.*?)(\\.ya?ml)?$", "$2")), "/[^a-zA-Z0-9-_]/", "-")) => yamldecode(file(file))
  }
}

resource "github_repository" "repos" {
  for_each = local.repos

  name        = substr(each.key, 0, 100)  # GitHub has a 100 character limit on repo names
  description = try(each.value.description, null)
  visibility  = try(each.value.visibility, "private")

  auto_init = try(each.value.auto_init, true)

  topics = try(each.value.topics, null)

  has_issues    = try(each.value.has_issues, true)
  has_projects  = try(each.value.has_projects, true)
  has_wiki      = try(each.value.has_wiki, true)
  has_downloads = try(each.value.has_downloads, true)
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