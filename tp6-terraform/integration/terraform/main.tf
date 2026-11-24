terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# Image du CV : construite localement (build_local = true) ou tirée de Docker Hub
resource "docker_image" "cv" {
  name         = var.cv_image
  keep_locally = true

  dynamic "build" {
    for_each = var.build_local ? [1] : []
    content {
      context = "${path.module}/cv"
    }
  }
}

resource "docker_container" "cv" {
  name    = "cv_onepage"
  image   = docker_image.cv.image_id
  restart = "unless-stopped"

  ports {
    internal = 80
    external = var.external_port
  }
}
