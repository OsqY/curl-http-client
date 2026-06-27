## ADDED Requirements

### Requirement: Monospace font for code-like fields
The system SHALL use a monospace font for URL input, header key-value editors, body content editors, script editors, and response body viewers.

#### Scenario: URL input font
- **WHEN** the user types in the URL field
- **THEN** the text is rendered in a monospace font family

#### Scenario: Body editor font
- **WHEN** the user edits the raw body content
- **THEN** the text is rendered in a monospace font family

#### Scenario: Response body font
- **WHEN** the response body is displayed
- **THEN** the syntax-highlighted text is rendered in a monospace font family at 13px

#### Scenario: Script editor font
- **WHEN** the user edits pre-request or post-response scripts
- **THEN** the text is rendered in a monospace font family
