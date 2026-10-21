# nginx-echo-headers

A small HTTP debugging endpoint built with OpenResty. It returns request metadata, headers, and the request body as **JSON**, making it useful for testing reverse proxies, ingress controllers, API gateways, and HTTP clients.

## Features

- Structured JSON response with method, URI, HTTP version, host, client IP, headers, and body.
- Redacts common credentials in headers, including authorization, cookies, API keys, tokens, secrets, and passwords.
- Limits incoming request bodies to 1 MiB and response body output to 64 KiB.
- `/healthz` endpoint for container and Kubernetes health checks.
- Logs to stdout/stderr and runs as a non-root user.
- Disables response caching and hides the Nginx version.

> **Security:** This service intentionally reflects request data. The request body is returned as sent and may contain passwords, tokens, or personal information. Header redaction is a best-effort safeguard, not a substitute for access control. Do not expose this service publicly or send production secrets to it. Put it behind trusted network controls and use synthetic test data.

## Run with Docker

Build the image:

```sh
docker build -t nginx-echo-headers:local .
```

Run it:

```sh
docker run --rm --name echo-headers -p 127.0.0.1:8080:8080 nginx-echo-headers:local
```

The port is bound to loopback by default so the debugging endpoint is not exposed to other network interfaces.

Check health:

```sh
curl -i http://127.0.0.1:8080/healthz
```

Send a request:

```sh
curl -sS http://127.0.0.1:8080/debug?source=local \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer example-token' \
  -H 'X-Api-Key: example-key' \
  -d '{"message":"hello"}'
```

Example response (header order may vary):

```json
{
  "method": "POST",
  "request_uri": "/debug?source=local",
  "http_version": 1.1,
  "host": "127.0.0.1",
  "remote_addr": "127.0.0.1",
  "headers": {
    "authorization": "[REDACTED]",
    "content-type": "application/json",
    "x-api-key": "[REDACTED]"
  },
  "headers_truncated": false,
  "body": "{\"message\":\"hello\"}",
  "body_truncated": false
}
```

Only selected fields are shown in the example; the response includes the other request headers too.

## Kubernetes notes

- Use `/healthz` for readiness and liveness probes on port `8080`.
- Keep the Service internal unless there is a specific, access-controlled debugging use case.
- Set ingress or gateway request-size limits as well; the in-container 1 MiB limit is not a replacement for edge limits.
- Treat echoed body content and all non-redacted headers as sensitive.

## Development and validation

The GitHub Actions workflow builds the container and checks health, JSON output, request body echoing, and credential-header redaction on pull requests.

## License

See the repository's license metadata, if provided.
