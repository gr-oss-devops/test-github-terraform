output "created_repo" {
  description = "URLs of the created repositories"
  value       = github_repository.repo.html_url
}