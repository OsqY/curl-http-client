## ADDED Requirements

### Requirement: Console is free of ListTile warnings
The system SHALL NOT produce `ListTile` warnings about invisible ink splashes in the debug console.

#### Scenario: App launches with empty workspace
- **WHEN** the app starts
- **THEN** the console shows no `ListTile` background color or ink splash warnings

### Requirement: Sidebar uses custom flat rows
The system SHALL render sidebar rows (collections, folders, requests, history) using a custom widget instead of `ListTile`.

#### Scenario: User hovers over a request in the sidebar
- **WHEN** the user hovers over a sidebar row
- **THEN** the row shows a subtle highlight and a hand cursor, with no material ink splash artifacts
