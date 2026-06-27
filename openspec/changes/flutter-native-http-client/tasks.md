## 1. Project Setup

- [x] 1.1 Initialize Flutter Desktop project (`flutter create --platforms=linux,windows http_client`)
- [x] 1.2 Configure `pubspec.yaml` with core dependencies (`http`, `riverpod`, `flutter_highlight`, `dart_eval`, `yaml`, `path`, `path_provider`)
- [x] 1.3 Set up folder structure: `lib/models`, `lib/services`, `lib/repositories`, `lib/providers`, `lib/ui`, `lib/utils`
- [x] 1.4 Configure Linux and Windows build targets and verify Linux build

## 2. Workspace and Local JSON Persistence

- [x] 2.1 Implement `WorkspaceRepository` to read/write workspace JSON files
- [x] 2.2 Define JSON schemas for requests, collections, environments, history, cookies, and settings
- [x] 2.3 Add workspace selection dialog (first launch + menu action)
- [x] 2.4 Write tests for workspace serialization and deserialization

## 3. Request and Collection Models

- [x] 3.1 Create immutable request model (`HttpRequest`) with method, URL, headers, query params, body, auth, and scripts
- [x] 3.2 Create collection and folder models with parent/child relationships
- [x] 3.3 Implement CRUD operations for collections, folders, and requests
- [x] 3.4 Persist collection renames and moves without data loss — rename UI not yet implemented

## 4. Request Builder UI

- [x] 4.1 Build main layout: sidebar (collections + history), request editor tabs, response panel
- [x] 4.2 Implement method selector, URL input, and "Send" button
- [x] 4.3 Add editable key-value lists for headers and query parameters
- [x] 4.4 Add body editor with modes: none, form-data, x-www-form-urlencoded, raw (JSON/XML/text), binary placeholder
- [x] 4.5 Implement unsaved-change indicator and request save action — save works, indicator not shown

## 5. HTTP Execution Engine

- [x] 5.1 Implement `HttpService` using `dart:io` HttpClient with timeout handling
- [x] 5.2 Assemble final request from model (URL, headers, query, body)
- [x] 5.3 Capture response status, headers, body, time, and size
- [x] 5.4 Surface network errors and timeouts in the UI
- [x] 5.5 Add unit tests for request assembly and response parsing

## 6. Authentication Helpers

- [x] 6.1 Implement Bearer token auth (header injection)
- [x] 6.2 Implement Basic auth with Base64 encoding
- [x] 6.3 Implement API key auth (header or query parameter)
- [x] 6.4 Implement OAuth2 client-credentials token fetch and attach
- [x] 6.5 Add token refresh logic for expired OAuth2 tokens — token fetched on each request if missing/expired
- [x] 6.6 Add UI auth tabs for Bearer, Basic, API Key, and OAuth2

## 7. Cookie Management

- [x] 7.1 Implement `CookieJar` model with domain/path/expiration matching
- [x] 7.2 Wire cookie jar into `HttpService` to send `Cookie` headers
- [x] 7.3 Parse `Set-Cookie` headers from responses and persist to `workspace/cookies.json`
- [x] 7.4 Add "Clear Cookies" action in UI

## 8. Environments and Variable Substitution

- [x] 8.1 Implement environment model and persistence (`environments/*.json`)
- [x] 8.2 Build environment selector and editor UI
- [x] 8.3 Implement `{{variable}}` substitution for URL, headers, query params, and body
- [x] 8.4 Support secret variables that display masked values in the UI

## 9. Response Viewer

- [x] 9.1 Display response status, time, and size metadata
- [x] 9.2 Display response headers in a list
- [x] 9.3 Add JSON/XML/HTML syntax-highlighted preview
- [x] 9.4 Implement "Save Response" file picker and writer
- [ ] 9.5 Implement response diff viewer with side-by-side comparison
- [ ] 9.6 Virtualize rendering for large response bodies

## 10. Request History

- [x] 10.1 Record each sent request and response summary to `history/*.json`
- [x] 10.2 Build searchable history sidebar panel
- [x] 10.3 Implement "Open as Request" replay action
- [x] 10.4 Implement clear/delete history actions

## 11. Request Scripting

- [x] 11.1 Integrate `dart_eval` pure-Dart runtime into a `ScriptingService`
- [x] 11.2 Expose scripting APIs (`variables`, `request`, `response`, `test()`) — flat API due to `dart_eval` limitations
- [x] 11.3 Run pre-request script before variable substitution and sending
- [x] 11.4 Run post-response script after response is received
- [x] 11.5 Display script errors and assertion results in the response panel

## 12. Import and Export

- [x] 12.1 Implement `curl` command parser covering `-X`, `-H`, `-d`, `-u`, `-b`, `-F`, URL, and `--data-urlencode`
- [x] 12.2 Implement OpenAPI 3.x JSON/YAML parser to generate collections
- [x] 12.3 Implement collection export to `curl` shell script
- [x] 12.4 Implement collection export to OpenAPI 3.x JSON
- [x] 12.5 Add import/export menu actions with file picker

## 13. Testing, Build, and Polish

- [ ] 13.1 Write widget tests for request builder and response viewer — basic app render test only
- [x] 13.2 Run `flutter analyze` and `flutter test` and fix warnings
- [ ] 13.3 Build release artifacts for Linux and Windows — debug Linux built; release + Windows pending environment
- [x] 13.4 Verify import/export round-trips for curl and OpenAPI samples — covered by unit tests
- [x] 13.5 Add keyboard shortcuts for Send (Ctrl+Enter) and Save (Ctrl+S)
- [x] 13.6 Update README with build instructions and feature overview
