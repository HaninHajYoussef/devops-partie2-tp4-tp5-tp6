variable "proxy_port" {
  description = "Port d'entrée unique sur la VM de lab"
  type        = number
  default     = 8000
}

variable "backends" {
  description = "Conteneurs CV derrière le proxy"
  type        = list(string)
  default     = ["192.168.61.11:8001", "192.168.61.12:8002"]
}
