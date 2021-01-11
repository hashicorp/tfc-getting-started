# The following variable is used to configure the provider's authentication
# token. You don't need to provide a token on the command line to apply changes,
# though: using the remote backend, Terraform will execute remotely in Terraform
# Cloud where your token is already securely stored in your workspace!

variable "token" {
  type = string
}

variable "hostname" {
  type = string
}

provider "fakewebservices" {
  token    = var.token
  hostname = var.hostname
}

provider "tfe" {
  hostname = var.hostname
  token    = var.token
}
