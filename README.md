# Terraform module for Amazon EC2 SSH key pairs

Imports an SSH public key into Amazon EC2 as a key pair. When you launch an instance with the key pair, EC2 puts the public key on it, so you can log in with the matching private key.

You create the key on your own computer, with `ssh-keygen`, and give the module only the public half. The private key never reaches AWS or Terraform.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Key pair name | None: required | `name` |
| Public key | None: required. ED25519 or RSA, in OpenSSH or RFC 4716 format | `public_key` |
| Region | The AWS provider's Region | `region` |
| Tags | `Scope`, `Purpose`, `Environment`, and any `additional_tags` | `details` |
| Private key | Never created or stored by the module | Not an input |

## Usage

```hcl
module "ssh_key_pair" {
  source  = "AutomateTheCloud/ssh_key_pair/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Web Site"
    environment = "Production"
  }

  name       = "web-site-admin"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"
  key_name      = module.ssh_key_pair.metadata.key_pair.key_name
}
```

`details`, `name` and `public_key` are the required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags. `name` is the key pair's name in EC2, which instances refer to.

The module uses your default `aws` provider and creates the key pair in that provider's Region. A key pair can be used only in its own Region. To create one somewhere else without configuring another provider, set `region`:

```hcl
module "ssh_key_pair_us_west_2" {
  source  = "AutomateTheCloud/ssh_key_pair/aws"
  version = "~> 1.0"

  region     = "us-west-2"
  details    = { scope = "Automate the Cloud", purpose = "Web Site", environment = "Production" }
  name       = "web-site-admin"
  public_key = file("~/.ssh/id_ed25519.pub")
}
```

Because `region` is an ordinary input, one module block can import the same key into several Regions with `for_each`, as the [complete example](https://github.com/AutomateTheCloud/terraform-aws-ssh_key_pair/tree/main/examples/complete) does.

To use a provider configured for another account, pass it explicitly with `providers = { aws = aws.other_account }`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the key pair belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Web Site"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a key pair in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the key pair, the instances launched with it, their VPC and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Web Site"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "site_key" {
  source  = "AutomateTheCloud/ssh_key_pair/aws"
  version = "~> 1.0"

  details    = local.details
  name       = "web-site-admin"
  public_key = file("~/.ssh/id_ed25519.pub")
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.site_key.metadata.key_pair.key_name` for the key pair's name, or `module.site_key.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration. Run it with `terraform init`, then `terraform apply -var "public_key=$(cat ~/.ssh/id_ed25519.pub)"`.

- [Basic SSH key pair](https://github.com/AutomateTheCloud/terraform-aws-ssh_key_pair/tree/main/examples/basic): one key pair in the provider's Region.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-ssh_key_pair/tree/main/examples/complete): the same key imported into two Regions from one module block, with `for_each` and `region`.

## Things to know

### Only the public key

Create the key on your own computer, for example with `ssh-keygen -t ed25519`, and pass the module the `.pub` file. Keep the private key where it is. The module rejects anything that looks like a private key, because every input is saved in the Terraform state in plain text.

Avoid generating the key inside Terraform with the `tls_private_key` resource: it works, but then the private key is saved in the state too, and anyone who can read the state can log in to your instances.

### Which keys EC2 accepts

EC2 accepts ED25519 and RSA keys, in OpenSSH format (the one-line `.pub` file) or RFC 4716 format. It rejects ECDSA and DSA keys, and keys kept on a security key (`sk-` types); the module rejects those at plan time. A trailing newline, as `file()` returns, is fine. ED25519 keys cannot be used with Windows instances: Windows uses the key pair to decrypt the administrator password, which needs an RSA key. See [Amazon EC2 key pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).

### Names

A key pair name can be 1 to 255 printable ASCII characters, including spaces and symbols, but not a space at the start or end. It must be unique among the key pairs in the account and Region; the same name can be used in another Region, as the complete example does.

### Changing or deleting the key pair

EC2 cannot change a key pair, so changing `name`, `public_key` or `region` deletes it and then imports a new one. For a moment in between, no key pair has that name, and launching an instance with it fails. Instances refer to a key pair by name. Changing `name` therefore also replaces every `aws_instance` whose `key_name` comes from this module. Changing only `public_key` keeps the name, so instances are not replaced. Changing only `details` updates the tags in place.

According to the [Amazon EC2 key pairs documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html), EC2 puts the public key on an instance when it is launched, and deleting or replacing the key pair does not change instances already running: they keep the key they were launched with. To change the key on a running instance, edit `~/.ssh/authorized_keys` on it.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-ssh_key_pair/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-ssh_key_pair/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-ssh_key_pair#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_name"></a> [name](#input_name)

Description: The key pair's name in EC2, such as `bastion`. It is what you choose when you launch an instance (`key_name` in `aws_instance` or a launch template). It must be unique among the key pairs in the account and Region, and be 1 to 255 printable ASCII characters, with no space at the start or end. Changing it replaces the key pair; instances that refer to it by name are replaced too.

Type: `string`

#### <a name="input_public_key"></a> [public_key](#input_public_key)

Description: The public half of an SSH key, in OpenSSH format (one line, as in `~/.ssh/id_ed25519.pub`) or RFC 4716 format. EC2 accepts ED25519 and RSA keys; it rejects ECDSA and DSA keys. Read it from a file with `file("~/.ssh/id_ed25519.pub")`, or pass it as a string. Never pass the private key: it would be stored in the Terraform state. Changing the key replaces the key pair. Instances already running keep the key they were launched with.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the key pair in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. A key pair can be used only by instances in its own Region; to use the same key in several Regions, call the module once per Region with the same `name` and `public_key`. Changing it replaces the key pair.

Type: `string`

Default: `null`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

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
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-ssh_key_pair/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-ssh_key_pair/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
