# Complete

The same public key imported as a key pair in two Regions, `us-east-1` and `us-west-2`, with one module block, `for_each` and the module's `region` input, while the provider is configured for `us-east-1`. A key pair can be used only in its own Region, so this is how to launch instances with one key in several Regions. Key pair names have to be unique only within a Region, so both are named `example-ssh-dev-bastion`.

Both share one `details` value, with short forms set for the purpose and environment and an extra `CostCenter` tag. The output shows each key pair's name, ID and fingerprint by Region; the fingerprints are the same, because the key is.

The example asks for the public key only. The private key stays on your computer; AWS and Terraform never see it. If you do not have a key yet, create one with `ssh-keygen -t ed25519`.

Key pairs cost nothing.

## Run it

```shell
terraform init
terraform apply -var "public_key=$(cat ~/.ssh/id_ed25519.pub)"
```

Remove it with `terraform destroy`, passing the same `-var`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_public_key"></a> [public_key](#input_public_key)

Description: Your SSH public key, such as the contents of ~/.ssh/id_ed25519.pub

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_key_pairs"></a> [key_pairs](#output_key_pairs)

Description: Each key pair's name, ID and fingerprint, by Region
<!-- END_TF_DOCS -->
