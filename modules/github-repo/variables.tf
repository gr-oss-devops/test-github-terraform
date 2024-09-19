variable "repo_name" {
  description = "The name of the repository"
  type        = string
}

variable "repo_description" {
  description = "A description of the repository"
  type        = string
}

variable "repo_visibility" {
  description = "The visibility of the repository (public or private)"
  type        = string
  default     = "private"
}

variable "repo_auto_init" {
  description = "Flag to indicate if the repository should be auto-initialized"
  type        = bool
  default     = true
}

variable "repo_topics" {
  description = "A list of topics for the repository"
  type        = list(string)
  default     = []
}

variable "repo_has_issues" {
  description = "Flag to enable issues for the repository"
  type        = bool
  default     = true
}

variable "repo_has_projects" {
  description = "Flag to enable projects for the repository"
  type        = bool
  default     = true
}

variable "repo_has_wiki" {
  description = "Flag to enable wiki for the repository"
  type        = bool
  default     = true
}

variable "repo_has_downloads" {
  description = "Flag to enable downloads for the repository"
  type        = bool
  default     = true
}