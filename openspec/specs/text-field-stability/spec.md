## Requirements

### Requirement: Text fields preserve cursor position during typing
The system SHALL NOT reset `TextEditingController.text` on every widget build. Controllers SHALL only be synchronized from state when the underlying request identity changes (different request ID), not when field values change due to user input.

#### Scenario: User types a URL character by character
- **WHEN** the user types "https://example.com" into the URL field one character at a time
- **THEN** each character is appended at the cursor position without selecting or overwriting existing text

#### Scenario: User pastes a URL
- **WHEN** the user pastes a URL into the URL field
- **THEN** the pasted text replaces the current selection and the cursor moves to the end of the pasted text

#### Scenario: User edits the middle of a URL
- **WHEN** the user clicks in the middle of an existing URL and types a character
- **THEN** the character is inserted at the click position without selecting or overwriting surrounding text

### Requirement: External request changes update text fields
The system SHALL update all text controllers when the active request changes to a different request (different ID), such as when the user selects a request from history or collections.

#### Scenario: User selects a different request from history
- **WHEN** the user clicks a history entry for a different request
- **THEN** the URL, name, body, and script fields update to reflect the new request's values

#### Scenario: User imports a curl command
- **WHEN** the user imports a curl command that replaces the current request
- **THEN** all text fields update to reflect the imported request's values

### Requirement: All editable text fields are stable
The fix SHALL apply to every text field in the request editor: URL, request name, raw body content, pre-request script, and post-response script.

#### Scenario: User edits the request body
- **WHEN** the user types in the body editor
- **THEN** the text is appended at the cursor without being overwritten

#### Scenario: User edits a pre-request script
- **WHEN** the user types in the pre-request script editor
- **THEN** the text is appended at the cursor without being overwritten
