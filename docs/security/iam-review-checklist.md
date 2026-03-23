# IAM Security Review Checklist

## 1. General Rules

- [ ] No IAM user with admin access
- [ ] MFA enabled for root user
- [ ] No hardcoded credentials
- [ ] Use IAM roles instead of users

---

## 2. Policies

- [ ] No "*" in actions unless required
- [ ] No "*" in resources unless justified
- [ ] Least privilege enforced
- [ ] Policies scoped per service

---

## 3. Roles

- [ ] Each service has its own role
- [ ] No shared roles across services
- [ ] Trust policies restricted properly

---

## 4. GitHub OIDC

- [ ] Only specific repo allowed
- [ ] Branch restrictions enforced
- [ ] No wildcard repo access

---

## 5. Secrets

- [ ] Secrets stored in AWS Secrets Manager
- [ ] No secrets in Terraform code
- [ ] Rotation enabled (if applicable)

---

## 6. Logging

- [ ] CloudTrail enabled
- [ ] IAM access logs monitored