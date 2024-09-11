output "files" {
  value = {
    for file in local.repo_configs :
    file => file
  }
}