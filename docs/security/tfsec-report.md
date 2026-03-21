# tfsec Security Scan Report

## Summary

Scan performed on Terraform codebase.

---

## Findings

### Example 1: S3 Bucket Public Access

- Issue: Public access allowed
- Severity: HIGH
- Fix:
  - Enable block_public_acls = true
  - Enable block_public_policy = true

---

### Example 2: Missing Encryption

- Issue: S3 bucket without encryption
- Fix:
  - Enable server_side_encryption_configuration

---

## Final Status

- Critical: 0
- High: 0
- Medium: X
- Low: X