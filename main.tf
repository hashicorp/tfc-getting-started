# The block below configures Terraform to use the 'remote' backend with Terraform Cloud.
# For more information, see https://www.terraform.io/docs/backends/types/remote.html
terraform {
  backend "remote" {
    organization = "{{ORGANIZATION_NAME}}"

    workspaces {
      name = "{{WORKSPACE_NAME}}"
    }
  }
}

resource "random_pet" "animal" {
  keepers = {
    uuid = "${uuid()}" # Force a new name each time
  }
  length = 3
}

output "random" {
  value = "${random_pet.animal.id}"
}
