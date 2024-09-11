output "created_repos" {
  description = "Create repos"
  value = [for repo in github_repository.repos : "${var.github_owner}/${repo.name}"]
}