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
echo "Terraform Cloud offers secure, easy-to-use remote state management and allows
you to run Terraform remotely in a controlled environment. Terraform Cloud runs can be
performed on demand or triggered automatically by various events."
echo
info "This script will set up everything you need to get started. You'll be
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
sleep 1

# We don't sed -i because MacOS's sed has problems with it.
TEMP=$(mktemp)
cat $MAIN_TF |
  sed "s/{{ORGANIZATION_NAME}}/${organization_name}/" |
  sed "s/{{WORKSPACE_NAME}}/${workspace_name}/" \
    > $TEMP
mv $TEMP $MAIN_TF

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
terraform init # Todo exit if this fails
echo
divider
echo
info "Now it’s time for 'terraform plan', to see what changes Terraform will perform:"
echo
echo "$ terraform plan"
echo
pause_for_confirmation

echo
terraform plan # Todo exit if this fails
echo
divider
echo
success "The plan is complete! You can view what changes Terraform needs to perform above."
echo
echo "This plan was initiated from your local machine, but executed within
Terraform Cloud! Terraform Cloud runs Terraform on disposable virtual machines in
its own cloud infrastructure."
echo
echo "This 'remote execution' helps provide consistency and visibility for
critical provisioning operations. It also enables powerful features like
Sentinel policy enforcement and cost estimation (shown in the output above),
notifications, version control integration, and more."
echo
info "To actually make changes, we'll run 'terraform apply'. We'll also auto-approve the
result, since this is an example:"
echo
echo "$ terraform apply -auto-approve"
echo
pause_for_confirmation

echo
terraform apply -auto-approve #TODO exit if this fails

echo
divider
echo
success "You did it! You just provisioned infrastructure with Terraform Cloud!"
echo
info "The organization we created here has a 30-day free trial of the Team &
Governance tier features. After the trial ends, you'll be moved to the Free tier."

echo
echo "This example configuration showcases only a small fraction of what Terraform Cloud offers.
Additional features include:"
echo "  * Workspaces for organizing your infrastructure."
echo "  * Remote state management, with the ability to share outputs across workspaces."
echo "  * Automatically trigger Terraform runs whenever you push to a connected repository,"
echo "    or use custom run triggers to create powerful automation pipelines."
echo "  * Easily share and reuse Terraform code with the private module registry."
echo "  * A rich API for nearly all Terraform Cloud features, enabling deep integrations."
echo
info "To see the mock infrastructure you just provisioned and continue exploring Terraform Cloud,
visit: https://$HOST/fake-web-services" # TODO: add the actual link
echo
exit 0
