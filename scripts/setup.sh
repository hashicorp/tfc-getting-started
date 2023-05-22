#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

info() {
  printf "\r\033[00;35m$1\033[0m\n"
}

success() {
  printf "\r\033[00;32m$1\033[0m\n"
}

fail() {
  printf "\r\033[0;31m$1\033[0m\n"
}

divider() {
  printf "\r\033[0;1m========================================================================\033[0m\n"
}

pause_for_confirmation() {
  read -rsp $'Press any key to continue (ctrl-c to quit):\n' -n1 key
}

# Set up an interrupt handler so we can exit gracefully
interrupt_count=0
interrupt_handler() {
  ((interrupt_count += 1))

  echo ""
  if [[ $interrupt_count -eq 1 ]]; then
    fail "Really quit? Hit ctrl-c again to confirm."
  else
    echo "Goodbye!"
    exit
  fi
}
trap interrupt_handler SIGINT SIGTERM

# This setup script does all the magic.

# Check for required tools
declare -a req_tools=("terraform" "sed" "curl" "jq")
for tool in "${req_tools[@]}"; do
  if ! command -v "$tool" > /dev/null; then
    fail "It looks like '${tool}' is not installed; please install it and run this setup script again."
    exit 1
  fi
done

# Get the minimum required version of Terraform
minimumTerraformMajorVersion=0
minimumTerraformMinorVersion=14
minimumTerraformVersion=$(($minimumTerraformMajorVersion * 1000 + $minimumTerraformMinorVersion))

# Get the current version of Terraform
installedTerraformMajorVersion=$(terraform version -json | jq -r '.terraform_version' | cut -d '.' -f 1)
installedTerraformMinorVersion=$(terraform version -json | jq -r '.terraform_version' | cut -d '.' -f 2)
installedTerraformVersion=$(($installedTerraformMajorVersion * 1000 + $installedTerraformMinorVersion))

# Check we meet the minimum required version
if [ $installedTerraformVersion -lt $minimumTerraformVersion ]; then
  echo
  fail "Terraform $minimumTerraformMajorVersion.$minimumTerraformMinorVersion.x or later is required for this setup script!"
  echo "You are currently running:"
  terraform version
  exit 1
fi

# Set up some variables we'll need
HOST="${1:-app.terraform.io}"
BACKEND_TF=$(dirname ${BASH_SOURCE[0]})/../backend.tf
PROVIDER_TF=$(dirname ${BASH_SOURCE[0]})/../provider.tf
TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')

# Check that we've already authenticated via Terraform in the static credentials
# file.  Note that if you configure your token via a credentials helper or any
# other method besides the static file, this script will not take that in to
# account - but we do this to avoid embedding a Go binary in this simple script
# and you hopefully do not need this Getting Started project if you're using one
# already!
CREDENTIALS_FILE="$HOME/.terraform.d/credentials.tfrc.json"

# Credentials are located in App/Data/Roaming on Windows
if [[ "$OSTYPE" =~ ^msys || "$OSTYPE" =~ ^cygwin || "$OSTYPE" =~ ^win32  ]]; then
    CREDENTIALS_FILE="$APPDATA/terraform.d/credentials.tfrc.json"
fi

TOKEN=$(jq -j --arg h "$HOST" '.credentials[$h].token' "$CREDENTIALS_FILE")
if [[ ! -f $CREDENTIALS_FILE || $TOKEN == null ]]; then
  fail "We couldn't find a token in the Terraform credentials file at $CREDENTIALS_FILE."
  fail "Please run 'terraform login', then run this setup script again."
  exit 1
fi

# Check that this is your first time running this script. If not, we'll reset
# all local state and restart from scratch!
if ! git diff-index --quiet --no-ext-diff HEAD --; then
  echo "It looks like you may have run this script before! Re-running it will reset any
  changes you've made to backend.tf and provider.tf."
  echo
  pause_for_confirmation

  git checkout HEAD backend.tf provider.tf
  rm -rf .terraform
  rm -f *.lock.hcl
fi

echo
printf "\r\033[00;35;1m
--------------------------------------------------------------------------
Getting Started with Terraform Cloud
-------------------------------------------------------------------------\033[0m"
echo
echo
echo "Terraform Cloud offers secure, easy-to-use remote state management and allows
you to run Terraform remotely in a controlled environment. Terraform Cloud runs
can be performed on demand or triggered automatically by various events."
echo
echo "This script will set up everything you need to get started. You'll be
applying some example infrastructure - for free - in less than a minute."
echo
info "First, we'll do some setup and configure Terraform to use Terraform Cloud."
echo
pause_for_confirmation

# Create a Terraform Cloud organization
echo
echo "Creating an organization and workspace..."
sleep 1
setup() {
  curl https://$HOST/api/getting-started/setup \
    --request POST \
    --silent \
    --header "Content-Type: application/vnd.api+json" \
    --header "Authorization: Bearer $TOKEN" \
    --header "User-Agent: tfc-getting-started" \
    --data @- << REQUEST_BODY
{
	"workflow": "remote-operations",
  "terraform-version": "$TERRAFORM_VERSION"
}
REQUEST_BODY
}

response=$(setup)
err=$(echo $response | jq -r '.errors')

if [[ $err != null ]]; then
  err_msg=$(echo $err | jq -r '.[0].detail')
  if [[ $err_msg != null ]]; then
    fail "An error occurred: ${err_msg}"
  else 
    fail "An unknown error occurred: ${err}"
  fi
  exit 1
fi

# TODO: If there's an active trial, we should just retrieve that and configure
# it instead (especially if it has no state yet)
info=$(echo $response | jq -r '.info')
if [[ $info != null ]]; then
  info "\n${info}"
  exit 0
fi

organization_name=$(echo $response | jq -r '.data."organization-name"')
workspace_name=$(echo $response | jq -r '.data."workspace-name"')

echo
echo "Writing Terraform Cloud configuration to backend.tf..."
sleep 2

# We don't sed -i because MacOS's sed has problems with it.
TEMP=$(mktemp)
cat $BACKEND_TF |
  # Add the backend config for the hostname if necessary
  # Note: sed 9a means append the string that follows \\ at line 9 in backend.tf
  if [[ "$HOST" != "app.terraform.io" ]]; then sed "9a\\
\    hostname = \"$HOST\"
    "; else cat; fi |
  # replace the organization and workspace names
  sed "s/{{ORGANIZATION_NAME}}/${organization_name}/" |
  sed "s/{{WORKSPACE_NAME}}/${workspace_name}/" \
    > $TEMP
mv $TEMP $BACKEND_TF

# add extra provider config for the hostname if necessary
if [[ "$HOST" != "app.terraform.io" ]]; then
  TEMP=$(mktemp)
  cat $PROVIDER_TF |
  # Note: sed 15a\\ means append the strings that follows the \\ at line 15 in provider.tf
    sed "15a\\
  \  hostname = var.provider_hostname
      " \
      > $TEMP
  echo "
variable \"provider_hostname\" {
  type = string
}" >> $TEMP
  mv $TEMP $PROVIDER_TF
fi

echo
divider
echo
success "Ready to go; the example configuration is set up to use Terraform Cloud!"
echo
echo "An example workspace named '${workspace_name}' was created for you."
echo "You can view this workspace in the Terraform Cloud UI here:"
echo "https://$HOST/app/${organization_name}/workspaces/${workspace_name}"
echo
info "Next, we'll run 'terraform init' to initialize the backend and providers:"
echo
echo "$ terraform init"
echo
pause_for_confirmation

echo
terraform init
echo
echo "..."
sleep 2
echo
divider
echo
info "Now it’s time for 'terraform plan', to see what changes Terraform will perform:"
echo
echo "$ terraform plan"
echo
pause_for_confirmation

echo
terraform plan
echo
echo "..."
sleep 3
echo
divider
echo
success "The plan is complete!"
echo
echo "This plan was initiated from your local machine, but executed within
Terraform Cloud!"
echo
echo "Terraform Cloud runs Terraform on disposable virtual machines in
its own cloud infrastructure. This 'remote execution' helps provide consistency
and visibility for critical provisioning operations. It also enables notifications,
version control integration, and powerful features like Sentinel policy enforcement
and cost estimation (shown in the output above)."
echo
info "To actually make changes, we'll run 'terraform apply'. We'll also auto-approve
the result, since this is an example:"
echo
echo "$ terraform apply -auto-approve"
echo
pause_for_confirmation

echo
terraform apply -auto-approve

echo
echo "..."
sleep 3
echo
divider
echo
success "You did it! You just provisioned infrastructure with Terraform Cloud!"
echo
info "The organization we created here has a 30-day free trial of the Team &
Governance tier features. After the trial ends, you'll be moved to the Free tier."
echo
echo "You now have:"
echo
echo "  * Workspaces for organizing your infrastructure. Terraform Cloud manages"
echo "    infrastructure collections with workspaces instead of directories. You"
echo "    can view your workspace here:"
echo "    https://$HOST/app/$organization_name/workspaces/$workspace_name"
echo "  * Remote state management, with the ability to share outputs across"
echo "    workspaces. We've set up state management for you in your current"
echo "    workspace, and you can reference state from other workspaces using"
echo "    the 'terraform_remote_state' data source."
echo "  * Much more!"
echo
info "To see the mock infrastructure you just provisioned and continue exploring
Terraform Cloud, visit:
https://$HOST/fake-web-services"
echo
exit 0
