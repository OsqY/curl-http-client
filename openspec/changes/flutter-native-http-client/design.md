## Context

This project builds a native desktop HTTP client comparable to Bruno or Postman. The primary constraint is performance: the MVP must avoid browser-based runtimes and use a compiled native framework. The target platforms are Linux and Windows, with all user data persisted locally as JSON files. The feature set covers request construction, execution, authentication, cookies, collections, environments, history, scripting, response viewing, and import/export.

## Goals / Non-Goals

**Goals:**
- Deliver a fast, offline-first Flutter Desktop application for Linux and Windows.
- Store requests, collections, environments, history, and responses as plain JSON files in a user-chosen workspace directory.
- Support all common HTTP verbs with headers, query parameters, and request bodies.
- Provide Bearer, Basic, API key, and OAuth2 client-credentials authentication helpers.
- Manage cookies automatically with a persistent cookie jar.
- Enable request organization via collections and folders.
- Support environment variables with substitution in URLs, headers, query params, and bodies.
- Keep a searchable request history.
- Run pre-request and post-response scripts to modify requests and assert responses.
- Import requests from `curl` commands and OpenAPI 3.x documents.
- Export collections to `curl` scripts and OpenAPI 3.x JSON/YAML.
- Render JSON, XML, and HTML responses with syntax highlighting; save responses; diff two responses.

**Non-Goals:**
- macOS support in the MVP.
- Cloud sync, collaboration, or user accounts.
- Full OAuth2 flows beyond client-credentials.
- gRPC, GraphQL, or WebSocket support in the MVP.
- Mobile or web deployment.
- Enterprise SSO or team features.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| UI framework | Flutter Desktop (Linux + Windows) | Compiles to native code, no browser runtime, single Dart codebase, mature desktop support, good performance, rich widget ecosystem. Alternatives: Avalonia (C#, good but smaller ecosystem), Qt (best native feel but heavier licensing/learning curve). |
| Networking layer | `dart:io` HttpClient + `http` package | `dart:io` HttpClient provides control over cookies, redirects, and timeouts; `http` package adds ergonomic request/response wrappers. `dio` is an alternative with interceptors, but adds complexity we can replicate in our own layer. |
| State management | Riverpod (or Provider/Bloc) | Riverpod is compile-safe, testable, and scales well with collections, environments, and history. Simpler alternatives like Provider could work but Riverpod reduces boilerplate for async data. |
| Persistence | JSON files on disk | Matches the requirement for local, human-readable storage. Each collection is a folder; requests are JSON files; environments and history are JSON files in a workspace root. SQLite was considered but adds binary/non-human-readable storage. |
| Workspace layout | `workspace/collections/<collection>/<folder>/<request>.json`, `workspace/environments/<name>.json`, `workspace/history/<id>.json`, `workspace/cookies.json`, `workspace/settings.json` | Keeps data portable, version-controllable, and easy to inspect. |
| Syntax highlighting | `flutter_highlight` or `code_text_field` | Provides fast client-side highlighting for JSON/XML/HTML without webviews. |
| Scripting | `flutter_js` or `dart_eval` | JavaScript is familiar to API users. `flutter_js` (QuickJS) is lightweight and embeddable. Alternative: a Dart DSL, but less user-friendly. |
| OAuth2 | Custom client-credentials flow | Implements token endpoint request, caches access token, and auto-attaches it to requests. Refresh logic included for client-credentials. Other flows (auth-code, implicit, device) are out of MVP scope. |
| Cookie jar | In-memory + persisted JSON | `dart:io` HttpClient can accept a custom `CookieJar`; we persist to `workspace/cookies.json`. |
| Diff viewer | Custom side-by-side text diff | Use a simple LCS-based diff or `diff_match_patch` package to highlight additions/deletions. |
| Import parsers | Hand-written parsers for `curl` and OpenAPI 3.x | `curl` parsing covers common flags (`-X`, `-H`, `-d`, `-u`, `-b`, `-F`, URL). OpenAPI parsing uses a lightweight YAML/JSON loader plus path/operation extraction. External packages exist but hand-written parsers keep control. |

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Flutter Desktop Linux/Windows plugin support may lag mobile. | Stick to core `dart:io` and well-maintained packages; test on both platforms early. |
| JavaScript scripting via `flutter_js` can be heavy or FFI-prone. | Start with a minimal `preRequest`/`postResponse` context object; evaluate QuickJS vs Duktoro alternatives if build issues arise. |
| Plain JSON storage may not scale to thousands of requests. | Use folder hierarchy and lazy loading; consider SQLite later if benchmarks show issues. |
| OAuth2 client-credentials token refresh can race. | Serialize token refresh per credential and use a short in-memory lock. |
| Rendering large response bodies can freeze the UI. | Virtualize large response text, cap syntax-highlighted length, and offer raw/download mode. |
| Import/export compatibility with Postman/Bruno is not required, but users may expect it. | Clearly document supported formats; Postman import can be added later. |

## Migration Plan

Not applicable for a greenfield MVP.

## Open Questions

- Should the workspace directory default to `~/.http-client` / `%APPDATA%\http-client` or prompt on first launch?
- Should scripts run synchronously or in an isolate to avoid blocking the UI?
- Should diff compare raw response bytes or formatted/pretty-printed bodies?
- Should collections be portable (relative paths) or tied to absolute workspace path?
