provider "github" {}

module "repository" {
  source          = "mineiros-io/repository/github"
  version         = "~> 0.18.0"
  name            = "unknown"
  default_branch  = "unknown"

  archive_on_destroy      = false
  issue_labels_create     = false
}