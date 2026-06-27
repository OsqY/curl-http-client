## ADDED Requirements

### Requirement: Users can create environments
The system SHALL provide a visible control next to the environment selector to create a new environment.

#### Scenario: User creates an environment
- **WHEN** the user clicks the new-environment button
- **THEN** the existing environment editor dialog opens for a new environment

### Requirement: Users can edit environments
The system SHALL provide a visible control next to the environment selector to edit the active environment.

#### Scenario: User edits an environment
- **WHEN** the user clicks the edit-environment button
- **THEN** the environment editor dialog opens with the active environment pre-filled

### Requirement: Users can delete environments
The system SHALL provide a delete option for the active environment inside a popup menu, with confirmation.

#### Scenario: User deletes an environment
- **WHEN** the user opens the environment options menu and selects delete
- **THEN** a confirmation dialog appears and confirming removes the environment
