import datetime
import json
import logging
import os
import uuid

import requests
import azure.functions as func

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient


app = func.FunctionApp()


def _get_blob_client() -> BlobServiceClient:
    storage_account = os.environ["DATA_STORAGE_ACCOUNT"]  # just the name
    account_url = f"https://{storage_account}.blob.core.windows.net"
    credential = DefaultAzureCredential()
    return BlobServiceClient(account_url=account_url, credential=credential)


def _write_raw_json(source: str, payload: dict) -> str:
    container = os.environ.get("RAW_CONTAINER", "raw")

    now = datetime.datetime.now(datetime.timezone.utc)
    ts = now.strftime("%Y%m%dT%H%M%SZ")
    blob_path = f"{source}/{now:%Y/%m/%d/%H}/{source}_{ts}_{uuid.uuid4().hex}.json"

    client = _get_blob_client()
    blob = client.get_blob_client(container=container, blob=blob_path)
    blob.upload_blob(json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8"), overwrite=False)

    return blob_path


def _fetch_json(url: str) -> dict:
    r = requests.get(url, timeout=20)
    return {
        "fetched_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "url": url,
        "status_code": r.status_code,
        "headers": dict(r.headers),
        "body": r.json() if "application/json" in (r.headers.get("content-type") or "") else {"text": r.text},
    }


@app.timer_trigger(
    schedule="%TIMER_SCHEDULE%",
    arg_name="mytimer",
    run_on_startup=False,
    use_monitor=False,
)
def ingest_timer(mytimer: func.TimerRequest) -> None:
    # Placeholder “smoke test” source. Replace later with your NFL calls.
    url = os.environ.get("SMOKE_TEST_URL", "https://httpbin.org/json")

    logging.info("Ingestion timer fired.")
    if mytimer.past_due:
        logging.warning("Timer is past due.")

    payload = _fetch_json(url)
    blob_path = _write_raw_json(source="smoke", payload=payload)
    logging.info("Wrote raw snapshot to blob: %s", blob_path)


@app.function_name(name="IngestNow")
@app.route(route="ingest/now", auth_level=func.AuthLevel.FUNCTION)
def ingest_now(req: func.HttpRequest) -> func.HttpResponse:
    # Same logic, but on-demand. Good for testing without waiting an hour.
    url = req.params.get("url") or os.environ.get("SMOKE_TEST_URL", "https://httpbin.org/json")
    payload = _fetch_json(url)
    blob_path = _write_raw_json(source="manual", payload=payload)
    return func.HttpResponse(f"OK: wrote {blob_path}\n", status_code=200)
