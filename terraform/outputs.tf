output "files" {
  value = {
    for k, v in data.local_file.repo_file : k => v.content
  }
}

output "repo_file_full_structure" {
  description = "Full decoded structure of each YAML file"
  value = local.decoded_yaml_files
}