## ADDED Requirements

### Requirement: Three-pane layout matching Insomnia
The system SHALL arrange the interface as: left sidebar (fixed width, resizable), center column containing request pane (top) and response pane (bottom) stacked vertically.

#### Scenario: Default layout
- **WHEN** the app launches
- **THEN** the sidebar appears on the left, the request editor fills the top-right, and the response panel fills the bottom-right, with a horizontal divider between request and response

#### Scenario: Sidebar content
- **WHEN** the user views the sidebar
- **THEN** it shows a tree of collections with expandable folders and requests, an environment selector dropdown at the top, and a history section

### Requirement: URL bar is a single horizontal bar
The system SHALL render the method selector, URL input, and Send button as a single horizontal bar at the top of the request pane, not as separate form fields.

#### Scenario: URL bar layout
- **WHEN** the user views the request pane
- **THEN** the method badge, URL input, and Send button appear on one row with no spacing between the method badge and URL input

### Requirement: Request and response panes are vertically stacked
The system SHALL stack the request pane above the response pane in the center column, with a draggable divider to resize.

#### Scenario: Resizing panes
- **WHEN** the user drags the divider between request and response
- **THEN** the request pane height decreases and the response pane height increases proportionally
