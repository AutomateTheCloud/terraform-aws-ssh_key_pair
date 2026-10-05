# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-ssh_key_pair#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "name" {
  description = <<-EOT
    The key pair's name in EC2, such as `bastion`. It is what you choose when you launch an instance (`key_name` in `aws_instance` or a launch template). It must be unique among the key pairs in the account and Region, and be 1 to 255 printable ASCII characters, with no space at the start or end. Changing it replaces the key pair; instances that refer to it by name are replaced too.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[ -~]{1,255}$", var.name)) && trimspace(var.name) == var.name
    error_message = "name must be 1 to 255 printable ASCII characters, with no space at the start or end."
  }
}

variable "public_key" {
  description = <<-EOT
    The public half of an SSH key, in OpenSSH format (one line, as in `~/.ssh/id_ed25519.pub`) or RFC 4716 format. EC2 accepts ED25519 and RSA keys; it rejects ECDSA and DSA keys. Read it from a file with `file("~/.ssh/id_ed25519.pub")`, or pass it as a string. Never pass the private key: it would be stored in the Terraform state. Changing the key replaces the key pair. Instances already running keep the key they were launched with.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.public_key) != ""
    error_message = "public_key not specified."
  }

  validation {
    condition     = !strcontains(var.public_key, "PRIVATE KEY")
    error_message = "public_key looks like a private key. Pass the public key (the .pub file); a private key would be stored in the Terraform state."
  }

  validation {
    condition     = !can(regex("^\\s*(ecdsa-|sk-|ssh-dss)", var.public_key))
    error_message = "EC2 accepts only ED25519 and RSA keys; ECDSA, DSA and security-key (sk-) keys are rejected."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the key pair in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. A key pair can be used only by instances in its own Region; to use the same key in several Regions, call the module once per Region with the same `name` and `public_key`. Changing it replaces the key pair.
  EOT
  type        = string
  default     = null
}
