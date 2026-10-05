# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The same public key imported in two Regions, us-east-1 and us-west-2, from one module
# block with for_each and the module's region input, so instances in either Region can
# be launched with the same key. Key pair names only need to be unique within a Region,
# so both copies have the same name. Both carry the same details and tags.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "public_key" {
  description = "Your SSH public key, such as the contents of ~/.ssh/id_ed25519.pub"
  type        = string
}

locals {
  details = {
    scope            = "Example"
    purpose          = "Complete SSH Key"
    purpose_abbr     = "ssh"
    environment      = "Development"
    environment_abbr = "dev"
    additional_tags  = { CostCenter = "1234" }
  }

  regions = toset(["us-east-1", "us-west-2"])
}

module "ssh_key_pair" {
  source   = "../../"
  for_each = local.regions

  region     = each.key
  details    = local.details
  name       = "example-ssh-dev-bastion"
  public_key = var.public_key
}

output "key_pairs" {
  description = "Each key pair's name, ID and fingerprint, by Region"
  value = {
    for region, m in module.ssh_key_pair : region => {
      key_name    = m.metadata.key_pair.key_name
      key_pair_id = m.metadata.key_pair.key_pair_id
      fingerprint = m.metadata.key_pair.fingerprint
    }
  }
}
