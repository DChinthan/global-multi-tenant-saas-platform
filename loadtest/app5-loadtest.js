import http from "k6/http";
import { check } from "k6";

// Point at the Helm-deployed app5-fileservice Service - e.g. via
// `kubectl port-forward svc/app5-app5-fileservice 8080:8080` and the
// default BASE_URL below, or pass -e BASE_URL=... for a different target
// (in-cluster ALB path /app5, a different kind/EKS/AKS cluster, etc).
const BASE_URL = __ENV.BASE_URL || "http://localhost:8080";

export const options = {
  scenarios: {
    ramping_load: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "10s", target: 10 },
        { duration: "20s", target: 20 },
        { duration: "10s", target: 0 },
      ],
    },
  },
  thresholds: {
    // /work has a real ~0.02-0.15s sleep (services/app5-fileservice/main.py)
    // plus network/scheduling overhead under load.
    http_req_duration: ["p(95)<500"],
    // /work injects a real ~1% synthetic error rate - the threshold gives
    // headroom above that baseline rather than requiring zero errors.
    http_req_failed: ["rate<0.05"],
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/work`);
  check(res, { "status is 200": (r) => r.status === 200 });
}
