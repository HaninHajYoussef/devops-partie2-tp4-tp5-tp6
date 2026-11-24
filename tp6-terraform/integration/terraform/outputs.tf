output "cv_container" {
  value = "${docker_container.cv.name} -> port ${var.external_port}"
}
