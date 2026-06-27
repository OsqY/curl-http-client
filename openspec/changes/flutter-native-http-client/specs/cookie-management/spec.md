## ADDED Requirements

### Requirement: Cookies are stored per domain
The system SHALL maintain a cookie jar that stores cookies keyed by domain and path.

#### Scenario: Receive Set-Cookie header
- **WHEN** a response includes `Set-Cookie: session=abc123; Path=/; Domain=.example.com`
- **THEN** the system stores the cookie in the jar and persists it to `workspace/cookies.json`

### Requirement: Cookies are sent automatically
The system SHALL include matching cookies in outgoing requests based on domain, path, and expiration.

#### Scenario: Send stored cookie
- **WHEN** the user sends a request to `https://example.com/orders`
- **THEN** the system includes any non-expired cookies for `example.com` and matching path

### Requirement: Session cookies are handled automatically
The system SHALL treat cookies without an explicit expiration as session cookies and keep them until the jar is cleared or the app exits.

#### Scenario: Session cookie lifecycle
- **WHEN** a response sets a session cookie
- **THEN** the cookie is retained across requests in the same app session and persisted to disk

### Requirement: Cookie jar can be cleared
The system SHALL allow the user to clear all stored cookies.

#### Scenario: Clear cookies
- **WHEN** the user selects "Clear Cookies"
- **THEN** the system empties the cookie jar and deletes the persisted cookie file
