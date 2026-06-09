import json
import logging
import os
import sys
from datetime import datetime, timezone

from flask import Flask, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest

PORT = int(os.environ.get("PORT", "3000"))

app = Flask(__name__)

app_requests_total = Counter(
    "app_requests_total",
    "Total number of HTTP requests handled by the application",
    ["method", "route", "status"],
)

app_errors_total = Counter(
    "app_errors_total",
    "Total number of application errors (5xx responses)",
    ["route"],
)


class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname.lower(),
            "message": record.getMessage(),
            "service": "observability-demo-app",
        }
        for key, value in record.__dict__.items():
            if key.startswith("_") or key in {
                "name",
                "msg",
                "args",
                "levelname",
                "levelno",
                "pathname",
                "filename",
                "module",
                "exc_info",
                "exc_text",
                "stack_info",
                "lineno",
                "funcName",
                "created",
                "msecs",
                "relativeCreated",
                "thread",
                "threadName",
                "processName",
                "process",
                "message",
                "taskName",
            }:
                continue
            payload[key] = value
        return json.dumps(payload)


logger = logging.getLogger("observability-demo-app")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
logger.handlers = [handler]
logger.propagate = False


@app.after_request
def after_request(response):
    app_requests_total.labels(
        method=request.method,
        route=request.path,
        status=str(response.status_code),
    ).inc()

    if response.status_code >= 500:
        app_errors_total.labels(route=request.path).inc()

    logger.info(
        "request completed",
        extra={
            "method": request.method,
            "route": request.path,
            "status": response.status_code,
        },
    )
    return response


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.get("/api/data")
def data():
    return jsonify({"items": ["alpha", "beta", "gamma"]})


@app.get("/api/error")
def error():
    logger.error("simulated server failure", extra={"route": "/api/error"})
    return jsonify({"error": "simulated failure"}), 500


@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    logger.info("server started", extra={"port": PORT})
    app.run(host="0.0.0.0", port=PORT)
