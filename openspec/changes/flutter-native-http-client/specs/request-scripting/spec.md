## ADDED Requirements

### Requirement: Pre-request scripts can modify request variables
The system SHALL execute a user-provided script before sending a request, with access to request variables and environment.

#### Scenario: Set timestamp header in pre-request script
- **WHEN** the pre-request script sets `pm.environment.set("now", Date.now())`
- **THEN** the system substitutes `{{now}}` in the request before sending

### Requirement: Post-response scripts can inspect response data
The system SHALL execute a user-provided script after receiving a response, with access to response status, headers, and body.

#### Scenario: Assert status code in post-response script
- **WHEN** the post-response script asserts `pm.response.status === 200`
- **THEN** the system reports the assertion result in the response panel

### Requirement: Scripts can access a minimal runtime API
The system SHALL expose a lightweight scripting API covering environment read/write, request metadata, response metadata, and basic console logging.

#### Scenario: Use scripting API
- **WHEN** a script calls `pm.environment.get("baseUrl")`
- **THEN** the system returns the current active environment value

### Requirement: Script errors are reported without crashing the app
The system SHALL catch script exceptions and display an error message in the UI.

#### Scenario: Invalid script
- **WHEN** a script throws an exception
- **THEN** the system shows the error in the response panel and does not crash
