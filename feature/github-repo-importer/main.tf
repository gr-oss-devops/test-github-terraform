provider "github" {}

module "repository" {
  source    = "mineiros-io/repository/github"
  version   = "~> 0.18.0"
  name      = var.repo_name

  allow_rebase_merge      = true
  allow_squash_merge      = true
  delete_branch_on_merge  = false
  has_downloads           = true
  has_issues              = true
  has_projects            = true
  has_wiki                = true
  archive_on_destroy      = false
  issue_labels_create     = false
}