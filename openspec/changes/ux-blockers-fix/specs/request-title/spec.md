## ADDED Requirements

### Requirement: Request title is visible and editable
The system SHALL display the active request's name as an editable text field directly in the request pane, above the URL bar.

#### Scenario: User renames a request
- **WHEN** the user types a new name into the title field
- **THEN** the request name updates in real time and persists when saved

#### Scenario: User switches requests
- **WHEN** the user selects a different request
- **THEN** the title field updates to show the new request's name

### Requirement: Title field follows cursor stability rules
The system SHALL use the same request-ID guard pattern used for the URL field to prevent text overwrite while typing.
