# Défi : reverse proxy nginx (point d'entrée unique) devant les 2 conteneurs CV.
# À lancer sur la VM de lab : terraform init && terraform apply
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

resource "docker_container" "proxy" {
  name    = "cv_reverse_proxy"
  image   = docker_image.nginx.image_id
  restart = "unless-stopped"

  ports {
    internal = 80
    external = var.proxy_port
  }

  upload {
    file    = "/etc/nginx/conf.d/default.conf"
    content = templatefile("${path.module}/nginx.conf.tftpl", { backends = var.backends })
  }
}
