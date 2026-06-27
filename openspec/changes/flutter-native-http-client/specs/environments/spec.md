## ADDED Requirements

### Requirement: Environments define variables
The system SHALL allow users to create named environments containing key-value variables.

#### Scenario: Create environment
- **WHEN** the user creates an environment named "Staging" with variable `baseUrl=https://staging.example.com`
- **THEN** the system persists it as `environments/staging.json`

### Requirement: Variables are substituted into requests
The system SHALL substitute environment variables into request URLs, headers, query parameters, and bodies using a `{{variableName}}` syntax.

#### Scenario: Substitute URL variable
- **WHEN** the user sends a request to `{{baseUrl}}/orders` with `baseUrl` set
- **THEN** the system replaces `{{baseUrl}}` with the environment value before sending

#### Scenario: Substitute header variable
- **WHEN** a header value is `Bearer {{authToken}}`
- **THEN** the system replaces `{{authToken}}` with the current environment value

### Requirement: Active environment is selectable
The system SHALL allow one active environment at a time, with an option for no environment.

#### Scenario: Switch environment
- **WHEN** the user selects the "Production" environment
- **THEN** all subsequent requests use variables from "Production" unless overridden
