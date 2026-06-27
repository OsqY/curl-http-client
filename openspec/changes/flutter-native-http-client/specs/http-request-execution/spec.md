## ADDED Requirements

### Requirement: Common HTTP verbs are supported
The system SHALL support GET, POST, PUT, PATCH, DELETE, HEAD, and OPTIONS.

#### Scenario: Send GET request
- **WHEN** the user selects GET and enters a URL
- **THEN** the system sends an HTTP GET request to that URL

#### Scenario: Send POST request with body
- **WHEN** the user selects POST, sets a JSON body, and sends
- **THEN** the system sends a POST request with the body and `Content-Type: application/json`

### Requirement: Request headers are configurable
The system SHALL allow adding, editing, removing, and toggling request headers.

#### Scenario: Add custom header
- **WHEN** the user adds header `X-Request-ID: 12345`
- **THEN** the system includes that header in the sent request

### Requirement: Query parameters are configurable
The system SHALL allow adding, editing, removing, and toggling query parameters.

#### Scenario: Add query parameter
- **WHEN** the user adds query parameter `status=pending`
- **THEN** the system appends `?status=pending` to the request URL

### Requirement: Request body supports common content types
The system SHALL support `none`, `form-data`, `x-www-form-urlencoded`, `raw` (JSON, XML, text), and `binary` body modes.

#### Scenario: Send raw JSON body
- **WHEN** the user selects raw body mode with content type JSON and enters valid JSON
- **THEN** the system sends the raw JSON as the request body

### Requirement: Redirects and timeouts are handled
The system SHALL follow redirects by default and allow configuring a request timeout.

#### Scenario: Timeout configuration
- **WHEN** the user sets a timeout of 30 seconds and the server does not respond in time
- **THEN** the system marks the request as timed out and displays an error
