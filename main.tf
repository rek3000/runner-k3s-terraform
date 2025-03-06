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
    "--disable", "metrics-server",  # Disable metrics-server to avoid errors
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

  networks_advanced {
    name = docker_network.k3s_network.name
  }

  ports {
    internal = 6443
    external = 6443
  }

  # More reliable health check - just check if the process exists
  healthcheck {
    test         = ["CMD-SHELL", "pidof k3s || exit 1"]
    interval     = "30s"
    timeout      = "10s"
    start_period = "60s"  # Increased to allow more startup time
    retries      = 3
  }

  restart = "unless-stopped"
}

# GitHub Runners
resource "docker_container" "github_runners" {
  count = var.github_runner_count
  name  = "${random_id.cluster_id.hex}-runner-${count.index + 1}"
  image = "myoung34/github-runner:latest"

  env = [
    "ORG_NAME=${var.github_org}",
    "RUNNER_NAME=${random_id.cluster_id.hex}-runner-${count.index + 1}",
    "RUNNER_TOKEN=${var.github_runner_token}",
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

  networks_advanced {
    name = docker_network.k3s_network.name
  }

  # Simplified health check that just checks if the container process is running
  healthcheck {
    test         = ["CMD", "pgrep", "-f", "Runner.Listener"]
    interval     = "30s"
    timeout      = "10s"
    start_period = "60s"  # Increased to allow more startup time
    retries      = 3
  }

  restart = "unless-stopped"

  depends_on = [docker_container.k3s_server]
}
