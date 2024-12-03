###########################################################
# K3S VARIABLES
###########################################################
variable "k3s_version" {
  description = "K3s version to install"
  type        = string
  default     = "latest"
}

###########################################################
# GITHUB RUNNER VARIABLES
###########################################################
variable "github_runner_token" {
  description = "GitHub Runner Token"
  type        = string
  sensitive   = true
}

variable "github_runner_count" {
  description = "GitHub Runner number"
  type        = number
  default   = 2
}

variable "github_org" {
  description = "GitHub Organization name"
  type        = string
}

# variable "github_repo" {
#   description = "GitHub repository (format: owner/repo)"
#   type        = string
# }

variable "github_runner_labels" {
  description = "GitHub Runner Labels"
  type        = list(string)
  default     = ["k3s", "hm"]
}


###########################################################
# DOCKER VARIABLES
###########################################################
variable "docker_network_cidr" {
  description = "Docker network CIDR"
  type        = string
  default     = "172.20.0.0/16"
}

# variable "runner_resources" {
#   description = "Resource limits for runners"
#   type = object({
#     cpu    = number
#     memory = number
#   })
#   default = {
#     cpu    = 2
#     memory = 4096
#   }
# }
