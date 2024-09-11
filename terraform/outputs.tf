output "files" {
  value = {
    for k, v in data.local_file.repo_file : k => v.content
  }
}