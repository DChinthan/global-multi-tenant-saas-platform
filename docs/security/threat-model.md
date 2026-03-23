# Threat Model — Global Multi-Tenant SaaS Platform

## 1. System Overview

This platform is a multi-tenant SaaS architecture deployed on AWS using:
- API Gateway + Lambda
- EventBridge + SQS + Step Functions
- S3 (data lake, logs)
- Cognito (authentication)
- WAF + CloudFront (edge security)

---

## 2. Trust Boundaries

1. Internet → CloudFront (WAF)
2. CloudFront → API Gateway
3. API Gateway → Lambda
4. Lambda → Internal AWS services
5. Cross-tenant isolation boundary

---

## 3. STRIDE Threat Analysis

### S — Spoofing Identity
- Risk: Fake users accessing APIs
- Mitigation:
  - Cognito JWT validation
  - API Gateway authorizer
  - IAM role-based access

---

### T — Tampering
- Risk: Data modification in transit or storage
- Mitigation:
  - HTTPS everywhere (TLS)
  - S3 versioning enabled
  - DynamoDB / S3 encryption (KMS)

---

### R — Repudiation
- Risk: Users deny actions
- Mitigation:
  - CloudTrail enabled
  - Structured logs in CloudWatch
  - Request IDs tracked

---

### I — Information Disclosure
- Risk: Data leak across tenants
- Mitigation:
  - Tenant isolation via IAM policies
  - S3 bucket policies
  - Encryption at rest (KMS)

---

### D — Denial of Service (DoS)
- Risk: API flooding
- Mitigation:
  - AWS WAF rate limiting
  - API Gateway throttling
  - CloudFront caching

---

### E — Elevation of Privilege
- Risk: Unauthorized admin access
- Mitigation:
  - Least privilege IAM
  - No wildcard (*) policies
  - Role assumption boundaries

---

## 4. High-Risk Areas

- Multi-tenant data isolation
- Public endpoints (API Gateway)
- Event-driven pipelines (event injection)

---

## 5. Security Controls Summary

| Area | Control |
|------|--------|
| Auth | Cognito + JWT |
| Network | WAF + CloudFront |
| Data | KMS encryption |
| Logs | CloudTrail + CloudWatch |
| Access | IAM least privilege |
