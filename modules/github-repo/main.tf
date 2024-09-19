resource "github_repository" "repo" {
  auto_init     = var.repo_auto_init
  description   = var.repo_description
  has_downloads = var.repo_has_downloads
  has_issues    = var.repo_has_issues
  has_projects  = var.repo_has_projects
  has_wiki      = var.repo_has_wiki
  name          = var.repo_name
  topics        = var.repo_topics
  visibility    = var.repo_visibility
}