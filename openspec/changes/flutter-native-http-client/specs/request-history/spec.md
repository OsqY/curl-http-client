## ADDED Requirements

### Requirement: Sent requests are recorded in history
The system SHALL record every sent request and its primary response metadata in a searchable history log.

#### Scenario: Send a request
- **WHEN** the user sends a request
- **THEN** the system appends an entry to history containing method, URL, timestamp, status code, and duration

### Requirement: History entries are searchable
The system SHALL allow searching history by URL, method, status code, and request name.

#### Scenario: Search history
- **WHEN** the user types "orders" into the history search field
- **THEN** the system displays only history entries whose URL or name contains "orders"

### Requirement: History can be replayed
The system SHALL allow reopening a history entry as a new request in the builder.

#### Scenario: Replay history entry
- **WHEN** the user selects a history entry and chooses "Open as Request"
- **THEN** the system populates the request builder with that request's configuration

### Requirement: History can be cleared
The system SHALL allow deleting individual history entries or clearing all history.

#### Scenario: Clear all history
- **WHEN** the user chooses "Clear History"
- **THEN** the system removes all history JSON files after confirmation
