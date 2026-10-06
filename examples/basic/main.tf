# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# One SSH key pair in the provider's Region, imported from your own public key.
# Launch instances with it by passing its name to key_name.

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

module "ssh_key_pair" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Basic SSH Key"
    environment = "Development"
  }

  name       = "example-basic"
  public_key = var.public_key
}

output "key_pair" {
  description = "The key pair's name, ID and fingerprint"
  value = {
    key_name    = module.ssh_key_pair.metadata.key_pair.key_name
    key_pair_id = module.ssh_key_pair.metadata.key_pair.key_pair_id
    fingerprint = module.ssh_key_pair.metadata.key_pair.fingerprint
  }
}
