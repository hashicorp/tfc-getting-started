#! /bin/bash
set -euo pipefail

# This setup script does all the magic.

# Check for required tools
declare -a req_tools=("terraform" "sed")
for tool in "${req_tools[@]}"; do
  if ! command -v "$tool"; then
    echo "It looks like '${tool}' not installed; please install it and run this setup script again."
    exit 1
  fi
done

echo "Enter an organization name: "
read organization_name

MAIN_TF=$(dirname ${BASH_SOURCE[0]})/../main.tf

# We don't sed -i because MacOS's sed has problems with it.
TEMP=$(mktemp)
cat $MAIN_TF \
    | sed "s/{{ORGANIZATION_NAME}}/${organization_name}/" \
    | sed "s/{{WORKSPACE_NAME}}/terraform-cloud-example/" \
    > $TEMP
mv $TEMP $MAIN_TF

echo "Ready to go; the example configuration is set to use Terraform Cloud as a remote backend!"
echo ""
echo "An example workspace, 'terraform-cloud-example', was created in your '${organization_name}' organization."
echo "You can view this workspace in the Terraform Cloud UI here: https://app.terraform.io/app/${organization_name}/workspaces/terraform-cloud-example"
echo ""
echo "Next, run 'terraform apply' apply the configuration in Terraform Cloud."

