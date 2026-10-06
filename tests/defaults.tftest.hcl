# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_key_pair" {
    defaults = {
      id          = "test-key"
      key_pair_id = "key-0123456789abcdef0"
      fingerprint = "SHA256:0123456789abcdef"
      key_type    = "ed25519"
    }
  }
}

variables {
  details    = { scope = "Test", purpose = "Defaults", environment = "test" }
  name       = "test-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl test@example.com"
}

# With only the required inputs, the module imports the key under the given name and
# tags it.
run "defaults_plan" {
  command = plan

  assert {
    condition = alltrue([
      aws_key_pair.this.key_name == "test-key",
      aws_key_pair.this.public_key == var.public_key,
      aws_key_pair.this.tags == tomap({ Scope = "Test", Purpose = "Defaults", Environment = "test" }),
    ])
    error_message = "Unexpected configuration with only the required inputs."
  }
}

run "defaults_apply" {
  command = apply

  assert {
    condition = alltrue([
      output.metadata.key_pair.key_name == "test-key",
      output.metadata.key_pair.key_pair_id == "key-0123456789abcdef0",
      output.metadata.key_pair.key_type == "ed25519",
      output.metadata.aws.region.name == "us-east-1",
      output.metadata.aws.region.abbr == "use1",
      output.metadata.aws.account.id == "111111111111",
      output.metadata.details.tags["Scope"] == "Test",
    ])
    error_message = "Unexpected metadata output."
  }
}

run "additional_tags" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "Defaults", environment = "test", additional_tags = { CostCenter = "1234" } }
  }
  assert {
    condition = aws_key_pair.this.tags == tomap({
      Scope       = "Test"
      Purpose     = "Defaults"
      Environment = "test"
      CostCenter  = "1234"
    })
    error_message = "Unexpected tags."
  }
}

# Regression: an empty abbreviation override used to replace the generated one with "".
run "abbreviation_override" {
  command = plan
  variables {
    details = { scope = "Automate the Cloud", scope_abbr = "atc-org", purpose = "SSH Key", purpose_abbr = "", environment = "Production" }
  }
  assert {
    condition = alltrue([
      output.metadata.details.scope.abbr == "atc-org",
      output.metadata.details.scope.machine == "atcorg",
      output.metadata.details.purpose.abbr == "ssh_key",
      output.metadata.details.purpose.machine == "sshkey",
      output.metadata.details.environment.abbr == "production",
    ])
    error_message = "Unexpected abbreviations."
  }
}

# RSA keys in RFC 4716 format are accepted by EC2, so the module accepts them too.
run "rfc4716_key_accepted" {
  command = plan
  variables {
    public_key = <<-EOT
      ---- BEGIN SSH2 PUBLIC KEY ----
      Comment: "2048-bit RSA"
      AAAAB3NzaC1yc2EAAAADAQABAAABAQC7
      ---- END SSH2 PUBLIC KEY ----
    EOT
  }
}

run "rsa_key_accepted" {
  command = plan
  variables { public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7 test@example.com" }
}

run "name_with_spaces_and_symbols_accepted" {
  command = plan
  variables { name = "Team key (2026) #1" }
}

run "name_255_characters_accepted" {
  command = plan
  variables { name = join("", [for i in range(255) : "k"]) }
}

# Regression: name and public_key defaulted to "", so name = null passed validation and
# the provider made up a name for the key pair. Both are now required, with no default,
# and not nullable: null fails with "Required variable not set" before any validation
# runs, which expect_failures cannot catch, so only the empty values are tested here.
run "name_required" {
  command = plan
  variables { name = "" }
  expect_failures = [var.name]
}

run "name_too_long" {
  command = plan
  variables { name = join("", [for i in range(256) : "k"]) }
  expect_failures = [var.name]
}

run "name_leading_space" {
  command = plan
  variables { name = " test-key" }
  expect_failures = [var.name]
}

run "name_trailing_space" {
  command = plan
  variables { name = "test-key " }
  expect_failures = [var.name]
}

run "name_not_ascii" {
  command = plan
  variables { name = "clé" }
  expect_failures = [var.name]
}

run "public_key_required" {
  command = plan
  variables { public_key = " \n" }
  expect_failures = [var.public_key]
}

run "public_key_private_key_rejected" {
  command = plan
  variables {
    public_key = <<-EOT
      -----BEGIN OPENSSH PRIVATE KEY-----
      b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
      -----END OPENSSH PRIVATE KEY-----
    EOT
  }
  expect_failures = [var.public_key]
}

run "public_key_ecdsa_rejected" {
  command = plan
  variables { public_key = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTY test@example.com" }
  expect_failures = [var.public_key]
}

run "public_key_dsa_rejected" {
  command = plan
  variables { public_key = "ssh-dss AAAAB3NzaC1kc3MAAACBAP test@example.com" }
  expect_failures = [var.public_key]
}

run "public_key_security_key_rejected" {
  command = plan
  variables { public_key = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29t test@example.com" }
  expect_failures = [var.public_key]
}

run "details_scope_required" {
  command = plan
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "details_purpose_required" {
  command = plan
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}

run "details_environment_required" {
  command = plan
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}
