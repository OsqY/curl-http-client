## ADDED Requirements

### Requirement: Flat IDE-style tabs for request configuration
The system SHALL render request configuration tabs (Params, Headers, Auth, Body, Scripts) as flat, compact tabs with no Material indicator elevation, using a bottom border for the active tab.

#### Scenario: Active tab indicator
- **WHEN** the user selects the "Headers" tab
- **THEN** the "Headers" tab shows a colored bottom border and the other tabs show no border

#### Scenario: Tab compactness
- **WHEN** the user views the request configuration tabs
- **THEN** tabs are compact with 8px horizontal padding, 6px vertical padding, and 13px font size

### Requirement: Flat tabs for response viewer
The system SHALL render response tabs (Body, Headers) as flat compact tabs matching the request configuration tab style.

#### Scenario: Response tab switching
- **WHEN** the user switches between Body and Headers in the response panel
- **THEN** the active tab shows a colored bottom border and the content area updates
