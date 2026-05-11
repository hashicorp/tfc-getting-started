# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

# The block below configures Terraform to use the 'remote' backend with HCP Terraform.
# For more information, see https://www.terraform.io/docs/backends/types/remote.html
terraform {
  cloud {
    organization = "{{ORGANIZATION_NAME}}"

    workspaces {
      name = "{{WORKSPACE_NAME}}"
    }
  }

  required_version = ">= 1.1.2"
}
