#! /bin/bash
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

# This setup script does all the magic.

# Check for required tools
declare -a req_tools=("terraform" "sed" "curl" "jq")
for tool in "${req_tools[@]}"; do
  if ! command -v "$tool" > /dev/null; then
    fail "It looks like '${tool}' is not installed; please install it and run this setup script again."
    exit 1
  fi
done

# Set up some variables we'll need
HOST="${1:-app.terraform.io}"
MAIN_TF=$(dirname ${BASH_SOURCE[0]})/../main.tf

# Check that we've already authenticated via Terraform in the static credentials
# file.  Note that if you configure your token via a credentials helper or any
# other method besides the static file, this script will not take that in to
# account - but we do this to avoid embedding a Go binary in this simple script
# and you hopefully do not need this Getting Started project if you're using one
# already!
CREDENTIALS_FILE="$HOME/.terraform.d/credentials.tfrc.json"
TOKEN=$(jq -j --arg h "$HOST" '.credentials[$h].token' $CREDENTIALS_FILE)
if [[ ! -f $CREDENTIALS_FILE || $TOKEN == null ]]; then
  fail "We couldn't find a token in the Terraform credentials file at $CREDENTIALS_FILE."
  fail "Please run 'terraform login', then run this setup script again."
  exit 1
fi

echo
info "Welcome to Terraform Cloud!"
echo
echo "Terraform Cloud is a platform that performs Terraform runs to provision
infrastructure, either on demand or in response to various events. Unlike a
general-purpose continuous integration (CI) system, it is deeply integrated with
Terraform's workflows and data, which allows it to make Terraform significantly
more convenient and powerful."
echo
info "This script will set up everything you need to get started. You'll be
applying some example infrastructure - for free - in less than a minute."
echo
read -n 1 -p "Continue? (y/n): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1


# Create a Terraform Cloud organization
echo
echo "Creating an organization and workspace..."
setup() {
  curl https://$HOST/api/getting-started/setup \
    --request POST \
    --silent \
    --header "Content-Type: application/vnd.api+json" \
    --header "Authorization: Bearer $TOKEN" \
    --header "User-Agent: tfc-getting-started" \
    --data @- << REQUEST_BODY
{
	"workflow": "remote-operations"
}
REQUEST_BODY
}

response=$(setup)

if [[ $(echo $response | jq -r '.errors') != null ]]; then
  fail "An unknown error occurred: ${response}"
  exit 1
fi

api_error=$(echo $response | jq -r '.error')
if [[ $api_error != null ]]; then
  fail "\n${api_error}"
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
echo "Writing remote backend configuration to main.tf..."

# We don't sed -i because MacOS's sed has problems with it.
TEMP=$(mktemp)
cat $MAIN_TF |
  sed "s/{{ORGANIZATION_NAME}}/${organization_name}/" |
  sed "s/{{WORKSPACE_NAME}}/${workspace_name}/" \
    > $TEMP
mv $TEMP $MAIN_TF

echo
success "Ready to go; the example configuration is set to use Terraform Cloud as a remote backend!"
echo
echo "An example workspace named '${workspace_name}' was created for you."
echo "You can view this workspace in the Terraform Cloud UI here:"
echo "https://$HOST/app/${organization_name}/workspaces/${workspace_name}"
echo
echo "Next, we'll run 'terraform init' to initialize the backend and providers:"
echo
echo "$ terraform init"
echo
read -n 1 -p "Continue? (y/n): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

echo
terraform init # Todo exit if this fails

echo
echo "$ terraform plan"
echo
read -n 1 -p "Continue? (y/n): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

echo
terraform plan # Todo exit if this fails

echo
success "The plan is complete! You can view what changes Terraform needs to perform
above. Note this is just an example, and the infrastructure here is totally
free."
echo
echo "Terraform Cloud runs Terraform on disposable virtual machines in its own
cloud infrastructure. Remote Terraform execution is sometimes referred to as
\"remote operations.\""
echo
echo "The plan above was initiated from your local machine, but executed within
Terraform Cloud! Remote execution helps provide consistency and visibility for
critical provisioning operations. It also enables powerful features like
Sentinel policy enforcement and cost estimation (shown in the output above),
notifications, version control integration, and more."
echo
echo "A plan phase by itself is called a 'speculative plan' in Terraform Cloud.
It's for a read-only view of the difference between your configuration and the real
world"
echo
echo "To actually make changes, we'll run 'terraform apply':"
echo
echo "$ terraform apply"
echo
read -n 1 -p "Continue? (y/n): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

echo
terraform apply #TODO exit if this fails and/or the user didn't confirm the plan

echo
success "You did it! You just applied a run in Terraform Cloud!"
echo
echo "Remember, you can view this workspace and the plan/apply operations we just
executed in the Terraform Cloud UI here: https://$HOST/app/${organization_name}/workspaces/${workspace_name}"
echo
info "The organization we created here has a 30-day free trial of the Team &
Governance tier features. Please feel free to continue to evaluate Terraform
Cloud with this workspace and configuration, however you wish!"
echo
echo "After the trial has ended, the organization will continue to be available
with Free tier features: https://www.terraform.io/docs/cloud/paid.html"

echo "This example configuration is only a small fraction of what Terraform Cloud offers:"
echo "  * Team-oriented remote execution and permissions system"
echo "  * Workspaces for organization infrastructure"
echo "  * Remote State Management, Data Sharing, and Run Triggers"
echo "  * Version Control Integration"
echo "  * Private Module Registry"
echo "  * Policy-as-Code with HashiCorp Sentinel"
echo "  * Cost Estimation"
echo "  * Terraform Cloud Agents for provisioning to private/on-premises infrastructure"
echo "  * A rich API for nearly all Terraform Cloud features - allowing deep
          integrations. There's even a Terraform provider for the API, allowing you to
          manage Terraform Cloud as a Terraform configuration."
echo "  * And more."
echo
echo "For more information, visit https://www.terraform.io/docs/cloud/overview.html"
exit 0
