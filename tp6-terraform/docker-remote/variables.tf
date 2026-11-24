variable "docker_host" {
  description = "Démon Docker distant (devopslab doit être dans /etc/hosts, ou mettre son IP)"
  type        = string
  default     = "ssh://hanin@devopslab:22"
}

variable "external_port" {
  type    = number
  default = 8001
}
