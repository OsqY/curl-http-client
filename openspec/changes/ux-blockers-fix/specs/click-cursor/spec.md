## ADDED Requirements

### Requirement: Interactive elements show a pointer cursor on desktop
The system SHALL display `SystemMouseCursors.click` when hovering over interactive desktop elements, except text fields which SHALL retain the text cursor.

#### Scenario: User hovers over the Send button
- **WHEN** the user hovers over the Send button
- **THEN** the cursor becomes a hand pointer

#### Scenario: User hovers over sidebar request rows
- **WHEN** the user hovers over a request in the sidebar
- **THEN** the cursor becomes a hand pointer

#### Scenario: User hovers over tabs
- **WHEN** the user hovers over request or response tabs
- **THEN** the cursor becomes a hand pointer

### Requirement: Click cursor covers non-text interactive elements
The system SHALL apply pointer cursor to at minimum: URL bar method dropdown, Send button, Save button, all tab labels, sidebar rows, sidebar action icons, collection header icons, environment selector icons, and New Request button. Text fields SHALL NOT use the pointer cursor.
