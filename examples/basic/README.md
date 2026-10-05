# Basic SSH key pair

One SSH key pair named `example-basic` in `us-east-1`, imported from a public key you supply. The output shows its name, ID and fingerprint. Launch an instance with it by passing the name to `key_name` in `aws_instance` or a launch template.

The example asks for the public key only. The private key stays on your computer; AWS and Terraform never see it. If you do not have a key yet, create one with `ssh-keygen -t ed25519`.

A key pair costs nothing.

## Run it

```shell
terraform init
terraform apply -var "public_key=$(cat ~/.ssh/id_ed25519.pub)"
```

Remove it with `terraform destroy`, passing the same `-var`. Deleting a key pair does not change instances already launched with it.

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

#### <a name="output_key_pair"></a> [key_pair](#output_key_pair)

Description: The key pair's name, ID and fingerprint
<!-- END_TF_DOCS -->
