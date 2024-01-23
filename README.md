# TFC Getting Started

In this repo, you'll find a quick and easy path to get started using [Terraform Cloud](https://app.terraform.io/) with the [Terraform CLI](https://github.com/hashicorp/terraform).

## What's here?

This repo contains two main things:

1. An example Terraform configuration which provisions some mock infrastructure to a fictitious cloud provider called "Fake Web Services" using the [`fakewebservices`](https://registry.terraform.io/providers/hashicorp/fakewebservices/latest) provider.
1. A [script](./scripts/setup.sh) which automatically handles all the setup required to start using Terraform with Terraform Cloud.

## Requirements

- Terraform 0.14 or higher
- The ability to run a bash script in your terminal
- [`sed`](https://www.gnu.org/software/sed/)
- [`curl`](https://curl.se/)
- [`jq`](https://stedolan.github.io/jq/)

## Usage

### 1. Log in to Terraform Cloud via the CLI

Run `terraform login` and follow the prompts to get an API token for Terraform to use. If you don't have a Terraform Cloud account, you can create one during this step.

### 2. Clone this repo

```sh
git clone https://github.com/hashicorp/tfc-getting-started.git
cd tfc-getting-started
```

### 3. Run the setup script and follow the prompts

```
./scripts/setup.sh
```

Welcome to Terraform Cloud!
