# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.0] - 2026-10-05

Initial release.

### Added

- An Amazon EC2 key pair, imported from an SSH public key in OpenSSH or RFC 4716 format.
- Checks at plan time for the key pair name, and for keys EC2 rejects: private keys, ECDSA, DSA and security-key types.
- `Scope`, `Purpose` and `Environment` tags from the `details` input.
- `region`, to create the key pair in a Region other than the provider's.
- A `metadata` output with the key pair's name, ID and fingerprint, and everything else the module created.
- Offline tests, and examples for one key pair and for the same key in two Regions.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-ssh_key_pair/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-ssh_key_pair/releases/tag/v1.0.0
