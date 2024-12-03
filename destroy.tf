resource "null_resource" "runner_deregistration" {
  count = var.github_runner_count
  depends_on = [docker_container.github_runners]

  triggers = {
    token     = var.github_runner_token
    name      = docker_container.github_runners[count.index].name
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      if docker inspect ${self.triggers.name} >/dev/null 2>&1; then
        echo "Deregistering runner ${self.triggers.name}..."
        docker exec ${self.triggers.name} ./config.sh remove --token ${self.triggers.token} || true

        docker stop ${self.triggers.name} || true
      fi
    EOT
  }


}
