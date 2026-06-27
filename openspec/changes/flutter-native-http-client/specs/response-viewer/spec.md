## ADDED Requirements

### Requirement: Response body preview supports JSON, XML, and HTML
The system SHALL render response bodies with syntax highlighting for JSON, XML, and HTML.

#### Scenario: Preview JSON response
- **WHEN** a response has `Content-Type: application/json`
- **THEN** the system pretty-prints and highlights the JSON body

#### Scenario: Preview XML response
- **WHEN** a response has `Content-Type: application/xml`
- **THEN** the system pretty-prints and highlights the XML body

### Requirement: Response metadata is visible
The system SHALL display status code, status text, response time, and response size.

#### Scenario: View response metadata
- **WHEN** a response is received
- **THEN** the system shows status, time, and size above the body preview

### Requirement: Response headers are inspectable
The system SHALL display response headers in a key-value list.

#### Scenario: View response headers
- **WHEN** the user selects the "Headers" tab
- **THEN** the system lists all response headers

### Requirement: Responses can be saved to disk
The system SHALL allow saving the full response body to a user-chosen file.

#### Scenario: Save response
- **WHEN** the user clicks "Save Response" and chooses a path
- **THEN** the system writes the response body to that file

### Requirement: Two responses can be diffed
The system SHALL allow selecting two saved responses and viewing a side-by-side diff with additions and deletions highlighted.

#### Scenario: Diff responses
- **WHEN** the user selects two history entries and chooses "Compare"
- **THEN** the system displays a diff of their response bodies
