provider "github" {}

module "repository" {
  source          = "mineiros-io/repository/github"
  version         = "~> 0.18.0"
  name            = "unknown"
  default_branch  = "unknown"

  archive_on_destroy      = false
  issue_labels_create     = false
}

resource "github_repository_ruleset" "unknown" {
    repository = module.repository.repository
    ruleset    = {
        "branch" = {
        "development" = {
            "enforce_admins"         = true
            "require_signed_commits" = true
        }
        }
    }
}