#! /bin/bash
set -euo pipefail

info () {
  printf "\r\033[00;35m$1\033[0m\n"
}

success () {
  printf "\r\033[00;32m$1\033[0m\n"
}

fail () {
  printf "\r\033[0;31m$1\033[0m\n"
}

# This setup script does all the magic.

# Check for required tools
declare -a req_tools=("terraform" "sed" "curl")
for tool in "${req_tools[@]}"; do
  if ! command -v "$tool" > /dev/null; then
    fail "It looks like '${tool}' is not installed; please install it and run this setup script again."
    exit 1
  fi
done

# Check that we've already authenticated via Terraform
CREDENTIALS_FILE="$HOME/.terraform.d/credentials.tfrc.json"
if [[ ! -f $CREDENTIALS_FILE ]]; then
  fail "It looks like the Terraform credentials file at $CREDENTIALS_FILE does not exist."
  fail "Please run 'terraform login', then run this setup script again."
  exit 1
fi

echo ""
info "Welcome to Terraform Cloud!"
echo "This script will set up everything you need to get started."
echo ""

# Set up some variables we'll need
HOST="${1:-app.terraform.io}"
TOKEN=$(jq -j --arg h "$HOST" '.credentials[$h].token' $CREDENTIALS_FILE)
MAIN_TF=$(dirname ${BASH_SOURCE[0]})/../main.tf
organization_name="sandbox-$RANDOM"
workspace_name="tfc-getting-started"

# Retrieve the user's account info (specifically, their email address)
echo "Retrieving your account info..."
get-account () {
  curl https://$HOST/api/v2/account/details \
    --silent \
    --header "Content-Type: application/vnd.api+json" \
    --header "Authorization: Bearer $TOKEN"
}

account=$(get-account)
email=$(jq -r '.data.attributes.email' <<< $account)
if [[ -z "$email" ]]; then
  fail "We couldn't retrieve your account information from Terraform Cloud."
  exit 1
fi

# Create a Terraform Cloud organization
echo "Creating an organization..."
create-org () {
  curl https://$HOST/api/v2/organizations \
    --request POST \
    --silent \
    --header "Content-Type: application/vnd.api+json" \
    --header "Authorization: Bearer $TOKEN" \
    --data @- << REQUEST_BODY
{
	"data": {
		"attributes": {
      "email": "$email",
			"name": "$organization_name"
		},
		"type": "organizations"
	}
}
REQUEST_BODY
}

org_response=$(create-org)
check_org_status=$(jq -r '.data.attributes.name' <<< $org_response)

if [[ -z "$check_org_status" ]]; then
  fail "We were unable to create a Terraform Cloud organization."
  exit 1
fi

# Create a Terraform Cloud workspace
echo "Creating a workspace..."
create-workspace () {
  curl https://$HOST/api/v2/organizations/$organization_name/workspaces \
    --request POST \
    --silent \
    --header "Content-Type: application/vnd.api+json" \
    --header "Authorization: Bearer $TOKEN" \
    --data @- << REQUEST_BODY
{
	"data": {
		"attributes": {
			"name": "$workspace_name"
		},
		"type": "workspaces"
	}
}
REQUEST_BODY
}

workspace_response=$(create-workspace)
check_workspace_status=$(jq -r '.data.attributes.name' <<< $workspace_response)

if [[ -z "$check_workspace_status" ]]; then
  fail "We were unable to create a Terraform Cloud workspace."
  exit 1
fi

# We don't sed -i because MacOS's sed has problems with it.
TEMP=$(mktemp)
cat $MAIN_TF \
    | sed "s/{{ORGANIZATION_NAME}}/${organization_name}/" \
    | sed "s/{{WORKSPACE_NAME}}/${workspace_name}/" \
    > $TEMP
mv $TEMP $MAIN_TF

echo ""
success "Ready to go; the example configuration is set to use Terraform Cloud as a remote backend!"
echo ""
echo "An example workspace, 'terraform-cloud-example', was created in your '${organization_name}' organization."
echo "You can view this workspace in the Terraform Cloud UI here: https://$HOST/app/${organization_name}/workspaces/terraform-cloud-example"
echo ""
success "Next, run 'terraform init' to initialize the backend and providers,"
success "then 'terraform apply' to apply the configuration in Terraform Cloud."
echo ""
