# The block below configures Terraform to use the 'remote' backend with Terraform Cloud.
# For more information, see https://www.terraform.io/docs/backends/types/remote.html
terraform {
  backend "remote" {
    hostname = "YOURSUBDOMAIN.ngrok.io" # This is only required for the demo

    organization = "{{ORGANIZATION_NAME}}"

    workspaces {
      name = "{{WORKSPACE_NAME}}"
    }
  }

  # This block is only required for the demo
  required_providers {
    fakewebservices = "1.0"
  }
}

variable "hostname" {
  type = string
}

variable "provider_token" {
  type = string
  sensitive = true
}

provider "fakewebservices" {
  hostname = var.hostname # This argument is only required for the demo
  token = var.provider_token
}

resource "fakewebservices_server" "server" {
  name = "my-demo-server"
}

output "server_name" {
  value = fakewebservices_server.server.name
}
