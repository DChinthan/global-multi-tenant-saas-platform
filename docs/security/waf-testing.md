# WAF Testing Report

## 1. Rate Limiting Test

Test:
- Sent 200 requests in 1 minute using curl

Command: for i in {1..200}; do curl https://api.example.com; done


Expected:
- Requests > threshold blocked

Result:
- WAF blocked after ~100 requests
- HTTP 403 returned

---

## 2. SQL Injection Test

Payload: curl "https://api.example.com?id=1' OR '1'='1"


Result:
- Blocked by AWS Managed Rules

---

## 3. XSS Test

Payload: <script>alert('xss')</script>


Result:
- Blocked successfully

---

## 4. Observability

- Logs verified in CloudWatch
- WAF metrics visible

---

## Conclusion

WAF effectively mitigates:
- DoS attacks
- Injection attacks
- Malicious payloads