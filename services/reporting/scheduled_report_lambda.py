import boto3
import csv
import io
import json
import os
import time
from datetime import datetime, timezone

athena = boto3.client("athena")
s3 = boto3.client("s3")


def run_query(query: str, database: str, workgroup: str, output_s3: str) -> str:
    response = athena.start_query_execution(
        QueryString=query,
        QueryExecutionContext={"Database": database},
        WorkGroup=workgroup,
        ResultConfiguration={"OutputLocation": output_s3},
    )
    return response["QueryExecutionId"]


def wait_for_query(query_execution_id: str, timeout_seconds: int = 45) -> None:
    start = time.time()
    while time.time() - start < timeout_seconds:
        response = athena.get_query_execution(QueryExecutionId=query_execution_id)
        state = response["QueryExecution"]["Status"]["State"]
        if state == "SUCCEEDED":
            return
        if state in ("FAILED", "CANCELLED"):
            reason = response["QueryExecution"]["Status"].get("StateChangeReason", "unknown")
            raise RuntimeError(f"Athena query {state}: {reason}")
        time.sleep(2)
    raise TimeoutError("Athena query timed out")


def fetch_results(query_execution_id: str):
    paginator = athena.get_paginator("get_query_results")
    rows = []
    headers = None

    for page in paginator.paginate(QueryExecutionId=query_execution_id):
        for idx, row in enumerate(page["ResultSet"]["Rows"]):
            values = [c.get("VarCharValue", "") for c in row["Data"]]
            if headers is None:
                headers = values
                continue
            rows.append(values)

    return headers or [], rows


def upload_csv(bucket: str, key: str, headers, rows):
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(headers)
    writer.writerows(rows)

    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=buffer.getvalue().encode("utf-8"),
        ContentType="text/csv",
    )


def lambda_handler(event, context):
    database = os.environ["ATHENA_DATABASE"]
    workgroup = os.environ["ATHENA_WORKGROUP"]
    output_s3 = os.environ["ATHENA_OUTPUT_S3"]
    report_bucket = os.environ["REPORT_BUCKET"]
    report_prefix = os.environ["REPORT_PREFIX"]
    query = os.environ["TENANT_SUMMARY_QUERY"]

    execution_id = run_query(query, database, workgroup, output_s3)
    wait_for_query(execution_id)
    headers, rows = fetch_results(execution_id)

    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%M-%SZ")
    key = f"{report_prefix}tenant-summary-{timestamp}.csv"

    upload_csv(report_bucket, key, headers, rows)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Scheduled report generated",
            "s3_key": key,
            "row_count": len(rows),
            "query_execution_id": execution_id
        })
    }