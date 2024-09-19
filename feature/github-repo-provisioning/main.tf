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

module "github_repos" {
  source              = "../../modules/github-repo"
  for_each            = local.repos

  repo_name           = each.key
  repo_description    = try(each.value.description, null)
  repo_visibility     = try(each.value.visibility, "private")
  repo_auto_init      = try(each.value.auto_init, true)
  repo_topics         = try(each.value.topics, [])
  repo_has_issues     = try(each.value.has_issues, true)
  repo_has_projects   = try(each.value.has_projects, true)
  repo_has_wiki       = try(each.value.has_wiki, true)
  repo_has_downloads  = try(each.value.has_downloads, true)
}