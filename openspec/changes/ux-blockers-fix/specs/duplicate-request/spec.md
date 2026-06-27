## ADDED Requirements

### Requirement: Users can duplicate a request
The system SHALL provide a "Duplicate" action that creates a copy of an existing request within the same collection.

#### Scenario: User duplicates a request
- **WHEN** the user right-clicks a request and selects "Duplicate"
- **THEN** a new request appears in the same collection with the same method, URL, headers, body, auth, and scripts, but a new ID and a "(copy)" suffix on the name

### Requirement: Duplicated request is immediately selectable
The system SHALL set the duplicated request as the active request after duplication.
