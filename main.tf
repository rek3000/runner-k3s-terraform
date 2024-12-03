# Random identifier for the cluster
resource "random_id" "cluster_id" {
  byte_length = 4
  prefix      = "k3s-"
}

# Docker network
resource "docker_network" "k3s_network" {
  name   = random_id.cluster_id.hex
  driver = "bridge"

  ipam_config {
    subnet  = var.docker_network_cidr
    gateway = cidrhost(var.docker_network_cidr, 1)
  }
}

# K3s data volume
resource "docker_volume" "k3s_data" {
  name = "${random_id.cluster_id.hex}-data"
}

# K3s Server
resource "docker_container" "k3s_server" {
  name  = "${random_id.cluster_id.hex}-server"
  image = "rancher/k3s:${var.k3s_version}"

  command = [
    "server",
    "--disable", "traefik",
    "--disable", "servicelb",
    "--tls-san", "0.0.0.0",
    "--kube-apiserver-arg", "feature-gates=TTLAfterFinished=true"
  ]

  env = [
    "K3S_TOKEN=${random_id.cluster_id.hex}",
    "K3S_KUBECONFIG_OUTPUT=/output/kubeconfig.yaml"
  ]

  privileged = true

  volumes {
    container_path = "/var/lib/rancher/k3s"
    volume_name    = docker_volume.k3s_data.name
  }

  # volumes {
  #   container_path = "/output"
  #   host_path      = "${path.module}/secrets"
  # }

  networks_advanced {
    name = docker_network.k3s_network.name
  }

  ports {
    internal = 6443
    external = 6443
  }

  # healthcheck {
  #   test         = ["CMD", "k3s", "kubectl", "get", "nodes"]
  #   interval     = "10s"
  #   timeout      = "5s"
  #   start_period = "10s"
  #   retries      = 3
  # }

  # resources {
  #   limits {
  #     cpu    = "2"
  #     memory = "2048M"
  #   }
  # }
}

# GitHub Runner Token

# GitHub Runners
resource "docker_container" "github_runners" {
  count = var.github_runner_count
  name  = "${random_id.cluster_id.hex}-runner-${count.index + 1}"
  image = "myoung34/github-runner:latest"

  env = [
    "ORG_NAME=${var.github_org}",
    "RUNNER_NAME=${random_id.cluster_id.hex}-runner-${count.index + 1}",
    "RUNNER_TOKEN=${var.github_pat}",
    "RUNNER_WORKDIR=/tmp/github-runner",
    "LABELS=${join(",", var.github_runner_labels)}",
    "RUNNER_GROUP=default",
    "RUNNER_SCOPE=org",
    "EPHEMERAL=1",
    "DISABLE_AUTO_UPDATE=1",
    "DOCKER_HOST=unix:///var/run/docker.sock",
    "KUBECONFIG=/etc/rancher/k3s/kubeconfig.yaml"
  ]

  volumes {
    container_path = "/var/run/docker.sock"
    host_path      = "/var/run/docker.sock"
  }

  # volumes {
  #   container_path = "/etc/rancher/k3s"
  #   host_path      = "${path.module}/secrets"
  # }

  networks_advanced {
    name = docker_network.k3s_network.name
  }

  # resources {
  #   limits {
  #     cpu    = var.runner_resources.cpu
  #     memory = "${var.runner_resources.memory}M"
  #   }
  #   reservations {
  #     cpu    = "0.5"
  #     memory = "512M"
  #   }
  # }

  # healthcheck {
  #   test         = ["CMD", "pgrep", "Runner.Listener"]
  #   interval     = "30s"
  #   timeout      = "10s"
  #   start_period = "30s"
  #   retries      = 3
  # }

  depends_on = [docker_container.k3s_server]

  # lifecycle {
  #   create_before_destroy = true
  #   replace_triggered_by = [
  #     data.external.github_runner_token.result.token
  #   ]
  # }
}

# Runner cleanup
# resource "null_resource" "runner_cleanup" {
#   count = var.github_runner_count
#
#   triggers = {
#     runner_id = docker_container.github_runners[count.index].id
#     pat       = var.github_pat
#     org       = var.github_org
#     name      = docker_container.github_runners[count.index].name
#   }
#
#   provisioner "local-exec" {
#     when    = destroy
#     command = <<-EOT
#       curl -s -X DELETE \
#         -H "Authorization: Bearer ${self.triggers.pat}" \
#         -H "Accept: application/vnd.github.v3+json" \
#         "https://api.github.com/orgs/${self.triggers.org}/actions/runners/${self.triggers.name}"
#     EOT
#   }
# }
