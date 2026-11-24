variable "external_port" {
  description = "Port externe du conteneur CV (8001 sur vm1, 8002 sur vm2)"
  type        = number
  default     = 8001
}

variable "cv_image" {
  description = "Image Docker du CV One Page (ton_compte/cv-onepage:latest)"
  type        = string
  default     = "haninhajyoussef/cv-onepage:latest"
}

variable "build_local" {
  description = "true = construire l'image sur la VM ; false = la tirer depuis Docker Hub"
  type        = bool
  default     = true
}
