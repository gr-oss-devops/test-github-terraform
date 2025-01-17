variable "owner" {
  description = "Org name"
  type        = string
}

variable "app_id" {
  description = "Github app id"
  type        = string
}

variable "app_installation_id" {
  description = "Github app installation id"
  type        = string
}

variable "pem_file" {
  description = "Github app pem file as string"
  type        = string
}