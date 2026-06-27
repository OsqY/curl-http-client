## ADDED Requirements

### Requirement: Bearer token authentication
The system SHALL support attaching an `Authorization: Bearer <token>` header to a request.

#### Scenario: Set Bearer auth
- **WHEN** the user selects Bearer auth and enters a token
- **THEN** the system includes the header in the sent request

### Requirement: Basic authentication
The system SHALL support Basic authentication by encoding username and password as Base64.

#### Scenario: Set Basic auth
- **WHEN** the user enters username "alice" and password "secret"
- **THEN** the system adds `Authorization: Basic YWxpY2U6c2VjcmV0`

### Requirement: API key authentication
The system SHALL support API keys in either a header or a query parameter.

#### Scenario: API key in header
- **WHEN** the user sets an API key named `X-API-Key` with value `abc123` in the header
- **THEN** the system sends the header `X-API-Key: abc123`

#### Scenario: API key in query
- **WHEN** the user sets an API key named `api_key` with value `abc123` in the query
- **THEN** the system appends `?api_key=abc123` to the request URL

### Requirement: OAuth2 client-credentials
The system SHALL implement OAuth2 client-credentials flow, fetch an access token from a token endpoint, and attach it to requests.

#### Scenario: Fetch and attach token
- **WHEN** the user configures client-credentials with client id, secret, token URL, and scope
- **THEN** the system requests a token and adds `Authorization: Bearer <access_token>` to the request

#### Scenario: Token refresh
- **WHEN** the stored access token is expired or missing
- **THEN** the system requests a new token before sending the request
