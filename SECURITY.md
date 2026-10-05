# Security

## Reporting a vulnerability

Report security problems privately, not in a public issue. On GitHub, open the repository's **Security** tab and choose **Report a vulnerability**. Only the maintainers can see the report.

Include what you found, how to reproduce it, and what an attacker could do with it.

## What counts

A security problem in this module is anything that could expose a private key or let someone else log in: for example, a private key reaching the Terraform state or an output, a key pair imported with a different key from the one the caller passed, or an option the module sets without being asked to.

## Supported versions

Fixes are made to the latest release.
