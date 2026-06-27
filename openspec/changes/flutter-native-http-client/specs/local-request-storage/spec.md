## ADDED Requirements

### Requirement: Workspace is stored as local JSON files
The system SHALL persist all user data in a user-selected workspace directory as plain JSON files.

#### Scenario: User opens a workspace
- **WHEN** the user selects a workspace directory
- **THEN** the system loads collections, environments, history, cookies, and settings from that directory

#### Scenario: User saves a request
- **WHEN** the user saves a request
- **THEN** the system writes or updates a JSON file in the appropriate collection folder

### Requirement: Storage format is human-readable and version-control friendly
The system SHALL use stable, deterministic JSON serialization for all persisted files.

#### Scenario: Inspecting stored data
- **WHEN** a user opens a persisted JSON file in an external editor
- **THEN** the contents represent the entity in a readable, self-describing structure
