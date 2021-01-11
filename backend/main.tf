# This is a proof of concept for bootstrapping an organization and workspace
# for use by the remote backend in the root module. Once bootstrapped, the
# organization and workspace will be managed via Terraform and any changes will
# update the org and workspace in TFC.

# To make it work:

# Export the following variables:
# export TF_VAR_hostname=blah-blah-blah.ngrok.io
# export TF_VAR_token=<USER TOKEN GOES HERE>

# Then run the following commands from the root module:

# terraform init -backend=false
# terraform apply -target=module.backend
#   (now it's time to uncomment the "terraform" block in the root module
#   and add the name of the org and workspace as noted in tf outputs)

# terraform init # will ask if you want to migrate state, say yes
#   (at this point, we need to rm terraform.tfstate*, or else we'll
#   get an error on the next step).

# terraform plan
# terraform apply

# Woohoo! remote backend bootstrapping complete.
terraform {
  required_providers {
    tfe = "~> 0.23.0"
  }
}

variable "token" {
  type = string
}

variable "hostname" {
  type = string
}

resource "random_pet" "org_name" {
  length = 3
}

resource "tfe_organization" "example" {
  name  = random_pet.org_name.id
  email = "thisIsAProblem@example.com" # how are we going to get this?
}

resource "tfe_workspace" "example" {
  name         = "getting-started"
  organization = tfe_organization.example.id
}

resource "tfe_variable" "hostname" {
  key          = "hostname"
  value        = var.hostname
  category     = "terraform"
  workspace_id = tfe_workspace.example.id
}

resource "tfe_variable" "token" {
  key          = "token"
  value        = var.token
  category     = "terraform"
  workspace_id = tfe_workspace.example.id
  sensitive    = true
}

output "organization" {
  description = "Name of the org"
  value       = tfe_organization.example.name
}

output "workspace" {
  description = "Name of the workspace"
  value       = tfe_workspace.example.name
}
