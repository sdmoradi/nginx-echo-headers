#!/usr/bin/env bash
set -euo pipefail

IMAGE="nginx-echo-headers:ci"
CONTAINER="nginx-echo-headers-ci"
PORT="18080"

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker build --pull -t "$IMAGE" .
docker run -d --name "$CONTAINER" -p "127.0.0.1:${PORT}:8080" "$IMAGE" >/dev/null

ready=false
for _ in $(seq 1 30); do
  if curl --fail --silent "http://127.0.0.1:${PORT}/healthz" >/dev/null; then
    ready=true
    break
  fi
  sleep 1
done

if [[ "$ready" != true ]]; then
  docker logs "$CONTAINER"
  echo "Container health endpoint did not become ready" >&2
  exit 1
fi

response="$(curl --fail --silent --show-error \
  -X POST "http://127.0.0.1:${PORT}/echo?test=1" \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer test-token' \
  -H 'X-Api-Key: test-api-key' \
  -H 'X-Custom-Token: test-custom-token' \
  --data '{"hello":"world"}')"

RESPONSE="$response" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["RESPONSE"])
assert data["method"] == "POST", data
assert data["request_uri"] == "/echo?test=1", data
assert data["headers"]["authorization"] == "[REDACTED]", data["headers"]
assert data["headers"]["x-api-key"] == "[REDACTED]", data["headers"]
assert data["headers"]["x-custom-token"] == "[REDACTED]", data["headers"]
assert data["body"] == '{"hello":"world"}', data
assert data["body_truncated"] is False, data
assert data["headers_truncated"] is False, data
print("Smoke tests passed.")
PY
