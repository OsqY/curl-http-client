# HTTP Client

A native, offline-first desktop HTTP client for Linux and Windows, built with Flutter Desktop. Inspired by Bruno and Postman, but without a browser runtime and with all data stored locally as plain JSON files.

## Features

- **Native performance** — Flutter Desktop compiles to native code for Linux and Windows.
- **Local JSON storage** — Requests, collections, environments, history, and cookies are persisted as human-readable JSON files in a workspace directory.
- **Request builder** — Common HTTP verbs, headers, query parameters, and request bodies (none, form-data, x-www-form-urlencoded, raw JSON/XML/text).
- **Authentication** — Bearer token, Basic auth, API key (header or query), and OAuth2 client-credentials.
- **Cookie jar** — Automatic session-style cookie handling with persistent storage.
- **Environments** — Named environments with `{{variable}}` substitution across URLs, headers, query params, and bodies.
- **Request history** — Searchable history with replay.
- **Scripting** — Pre-request and post-response Dart scripts via `dart_eval`.
- **Import / Export** — Import from `curl` commands and OpenAPI 3.x JSON/YAML; export collections to `curl` scripts and OpenAPI 3.x JSON.
- **Response viewer** — Syntax-highlighted JSON, XML, and HTML; response metadata; save response to disk.

## Project Structure

```
lib/
  models/           # Data models (request, collection, environment, history, etc.)
  services/         # HTTP engine, cookie jar, auth, scripting, import/export
  repositories/     # Workspace JSON persistence
  providers/        # Riverpod state management
  ui/               # Screens and widgets
  utils/            # Formatting, variable substitution, helpers
```

## Build

### Linux

```bash
cd http_client
flutter build linux --release
```

The release bundle will be in `build/linux/x64/release/bundle/`.

### Windows

```bash
cd http_client
flutter build windows --release
```

The release bundle will be in `build/windows/x64/runner/Release/`.

## Run

```bash
cd http_client
flutter run -d linux
```

## Test

```bash
cd http_client
flutter test
```

## Workspace Layout

The default workspace is created at `~/Documents/http_client_workspace/`:

```
http_client_workspace/
  collections/
    <collection-name>/
      collection.json
      <request-name>.json
      <folder-name>/
        <request-name>.json
  environments/
    <environment-name>.json
  history/
    <entry-id>.json
  cookies.json
  settings.json
```

## Notes

- The original plan used `flutter_js` for JavaScript scripting, but it required a newer native toolchain than the Flutter snap provides. We switched to `dart_eval`, a pure-Dart scripting runtime, to keep builds reliable.
- Windows builds must be produced on a Windows host.
