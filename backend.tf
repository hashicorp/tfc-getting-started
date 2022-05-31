# The block below configures Terraform to use the 'remote' backend with Terraform Cloud.
# For more information, see https://www.terraform.io/docs/backends/types/remote.html
terraform {
  # cloud {
  #   organization = "example-org-78f96f"
  #   workspaces {
  #     name = "getting-started"
  #   }
  # }
  required_providers {
    fakewebservices = "~> 0.1"
	}
	required_version = ">= 0.13.0"
}
