# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
    - `key_pair` - The key pair:

      - `key_name` - The name to launch instances with: pass it to `key_name` in `aws_instance` or a launch template. `id` is the same value.
      - `key_pair_id` - The key pair's ID, such as `key-0123456789abcdef0`.
      - `fingerprint` - The fingerprint AWS shows in the console, to check which key this is. For an RSA key, the MD5 hash of the key, as `ssh-keygen -e -m PKCS8 -f key.pub | openssl pkey -pubin -outform DER | openssl md5 -c` prints it; for an ED25519 key, the SHA-256 hash that `ssh-keygen -l -f key.pub` prints, with a trailing `=`.
      - `key_type` - `ed25519` or `rsa`.
      - `public_key` - The public key, as passed in, without a trailing newline.
      - `arn`, `region`, `tags` and `tags_all`.
      - `key_name_prefix` - A setting the module does not use. Empty.
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    # One entry per resource.
    key_pair = local.output_resources.key_pair
  }
}

locals {
  # Each resource's attributes are listed one by one. Referencing a whole resource
  # would also reference any attribute the provider deprecates later, and every
  # caller's plan would print deprecation warnings.
  output_resources = {
    key_pair = {
      arn             = aws_key_pair.this.arn
      fingerprint     = aws_key_pair.this.fingerprint
      id              = aws_key_pair.this.id
      key_name        = aws_key_pair.this.key_name
      key_name_prefix = aws_key_pair.this.key_name_prefix
      key_pair_id     = aws_key_pair.this.key_pair_id
      key_type        = aws_key_pair.this.key_type
      public_key      = aws_key_pair.this.public_key
      region          = aws_key_pair.this.region
      tags            = aws_key_pair.this.tags
      tags_all        = aws_key_pair.this.tags_all
    }
  }
}
