## ADDED Requirements

### Requirement: Import requests from curl commands
The system SHALL parse a `curl` command string and create a corresponding request.

#### Scenario: Import curl with headers and body
- **WHEN** the user pastes `curl -X POST https://api.example.com/orders -H "Content-Type: application/json" -d '{"a":1}'`
- **THEN** the system creates a POST request with the URL, header, and JSON body

#### Scenario: Import curl with Basic auth
- **WHEN** the user pastes `curl -u alice:secret https://api.example.com/orders`
- **THEN** the system creates a request with Basic authentication

### Requirement: Import requests from OpenAPI 3.x documents
The system SHALL parse OpenAPI 3.x JSON or YAML files and generate a collection of requests.

#### Scenario: Import OpenAPI JSON
- **WHEN** the user imports an OpenAPI 3.0 JSON file with paths `/users` and `/orders`
- **THEN** the system creates a collection containing requests for each operation

#### Scenario: Import OpenAPI with server URL
- **WHEN** the OpenAPI document defines a `servers` entry
- **THEN** the system uses the first server URL as the request base URL

### Requirement: Export collection to curl script
The system SHALL export a collection as a shell script containing equivalent `curl` commands.

#### Scenario: Export collection to curl
- **WHEN** the user exports a collection named "Payments API"
- **THEN** the system writes a file with one `curl` command per request

### Requirement: Export collection to OpenAPI 3.x
The system SHALL export a collection as an OpenAPI 3.x JSON document.

#### Scenario: Export collection to OpenAPI
- **WHEN** the user exports a collection
- **THEN** the system writes an OpenAPI 3.x JSON file with paths derived from request URLs
