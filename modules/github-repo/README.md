# GitHub Repo Provisioning Module

This Terraform module provisions GitHub repositories.

## Usage

```hcl
module "github_repos" {
  source = "./github-repo-provisioning"

  github_token = var.github_token
  github_owner = var.github_owner
  repos = {
    repo1 = {
      description = "Repository 1"
      visibility  = "private"
      auto_init   = true
      topics      = ["example", "terraform"]
      has_issues  = true
      has_projects = true
      has_wiki    = true
      has_downloads = true
    }
  }
}