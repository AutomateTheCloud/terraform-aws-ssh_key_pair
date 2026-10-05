# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_key_pair" "this" {
  region     = var.region
  key_name   = var.name
  public_key = var.public_key
  tags       = local.tags
}
