## Why

Existing HTTP clients like Postman and Bruno either ship a heavy browser runtime or use proprietary/cloud-first storage. There is room for a lean, truly native desktop HTTP client that stores requests locally as plain JSON, starts fast, and remains fully offline. This change establishes the MVP of that client using Flutter Desktop for Linux and Windows.

## What Changes

- Create a new Flutter Desktop application targeting Linux and Windows.
- Store all user data (requests, collections, environments, history) as local JSON files on disk.
- Implement a request builder supporting common HTTP verbs, headers, query parameters, and request bodies.
- Add authentication helpers: Bearer token, Basic auth, API key, and OAuth2 client-credentials flow.
- Add automatic session-style cookie handling with a local cookie jar.
- Organize requests into collections with nested folders.
- Support environment variables scoped globally or per-collection.
- Keep a searchable request history.
- Add pre-request and post-response scripting hooks using a lightweight embedded runtime.
- Import requests from `curl` commands and OpenAPI 3.x documents.
- Export collections back to `curl` scripts and OpenAPI 3.x JSON/YAML.
- Render responses with syntax highlighting for JSON, XML, and HTML; save responses to disk; and diff two responses side-by-side.

## Capabilities

### New Capabilities

- `local-request-storage`: Persist requests, collections, environments, and history as plain JSON files on the local filesystem.
- `collections`: Organize requests into hierarchical collections and folders.
- `environments`: Define key-value environment variables with substitution in request URLs, headers, and bodies.
- `request-history`: Record every sent request and its response summary for quick recall and search.
- `auth-management`: Attach Bearer, Basic, API key, and OAuth2 client-credentials authentication to requests.
- `cookie-management`: Maintain an automatic session cookie jar per request and per domain.
- `http-request-execution`: Send common HTTP verbs with configurable headers, query params, and bodies.
- `response-viewer`: Preview JSON/XML/HTML responses with syntax highlighting, save bodies, and diff two responses.
- `request-scripting`: Run pre-request and post-response scripts to modify requests and assert responses.
- `import-export`: Import from `curl` commands and OpenAPI 3.x; export collections to `curl` and OpenAPI 3.x.

### Modified Capabilities

- None.

## Impact

- New Flutter project under the repository root.
- New dependencies: `http`, `dio`, or `curl` bindings for networking; syntax highlighting and scripting packages.
- Local filesystem schema for JSON-based persistence.
- No backend, cloud, or authentication services required.
