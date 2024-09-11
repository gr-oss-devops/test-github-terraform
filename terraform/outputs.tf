output "repository_urls" {
  value = {
    for repo in github_repository.repos :
    repo.name => repo.html_url
  }
  description = "URLs of the created repositories"
}

output "repository_ssh_clone_urls" {
  value = {
    for repo in github_repository.repos :
    repo.name => repo.ssh_clone_url
  }
  description = "SSH clone URLs of the created repositories"
}