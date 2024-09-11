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
}

data "local_file" "repo_file" {
  for_each = toset(local.repo_configs)
  filename = each.value
}

# Step 3: Create a map where the key is the stripped file name and the value is the decoded YAML content
locals {
  repos = {
    for file_path, file_data in data.local_file.repo_file :
    split(".", basename(file_path))[0] => yamldecode(file_data.content)
  }
}

# Step 4: Create GitHub repositories using the decoded YAML content
resource "github_repository" "repos" {
  for_each = local.repos

  name        = each.key
  description = try(each.value.description, null)
  visibility  = try(each.value.visibility, "private")  # Default visibility is private

  auto_init = try(each.value.auto_init, true)  # Default auto_init is true

  topics = try(each.value.topics, null)

  has_issues    = try(each.value.has_issues, true)
  has_projects  = try(each.value.has_projects, true)
  has_wiki      = try(each.value.has_wiki, true)
  has_downloads = try(each.value.has_downloads, true)
}