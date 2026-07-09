import os
import random
import time
import uuid

from fastapi import APIRouter, FastAPI, HTTPException

app = FastAPI(title="app5-fileservice")

CLOUD_PROVIDER = os.environ.get("CLOUD_PROVIDER", "aws")
START_TIME = time.time()

# Mocked presigned-URL shapes per provider - no real cloud SDK calls are made.
# The point is to prove one codebase + one Helm chart can be re-pointed at a
# different provider (see helm/app5-fileservice/values-azure.yaml) purely via
# CLOUD_PROVIDER, without a code change.
_PRESIGN_TEMPLATES = {
    "aws": "https://{bucket}.s3.amazonaws.com/{key}?X-Amz-Signature=mock",
    "gcp": "https://storage.googleapis.com/{bucket}/{key}?X-Goog-Signature=mock",
    "azure": "https://{account}.blob.core.windows.net/{bucket}/{key}?sig=mock",
}

router = APIRouter()


@router.get("/healthz")
def healthz():
    """Liveness: process is up and can accept connections."""
    return {"status": "ok"}


@router.get("/readyz")
def readyz():
    """Readiness: process has finished startup."""
    return {"status": "ready", "uptime_seconds": round(time.time() - START_TIME, 2)}


@router.get("/presign")
def presign(bucket: str = "demo-bucket", key: str = "demo-object.txt"):
    template = _PRESIGN_TEMPLATES.get(CLOUD_PROVIDER)
    if template is None:
        raise HTTPException(status_code=500, detail=f"unknown CLOUD_PROVIDER: {CLOUD_PROVIDER}")

    return {
        "cloud_provider": CLOUD_PROVIDER,
        "bucket": bucket,
        "key": key,
        "url": template.format(bucket=bucket, key=key, account="demoaccount"),
        "expires_in": 900,
        "mocked": True,
    }


@router.get("/work")
def work():
    """Simulated workload: variable latency + ~1% synthetic error rate.

    This is the endpoint loadtest/app5-loadtest.js and chaos/app5-pod-kill.sh
    exercise - the latency/error numbers are generated here, not faked in docs.
    """
    time.sleep(random.uniform(0.02, 0.15))

    if random.random() < 0.01:
        raise HTTPException(status_code=500, detail="synthetic error")

    return {"request_id": str(uuid.uuid4()), "cloud_provider": CLOUD_PROVIDER}


# Mounted twice: at root for direct access (local docker run, Kubernetes
# Service/Ingress, the k6/chaos scripts) and again under /app5 so the shared
# ECS ALB - which does path-based routing without rewriting the path - can
# route /app5/* to this service without every other service needing the
# same prefix. See infra/terraform/modules/compute/alb.tf.
app.include_router(router)
app.include_router(router, prefix="/app5")
