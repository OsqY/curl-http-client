## ADDED Requirements

### Requirement: App uses a custom dark theme matching Insomnia's palette
The system SHALL use a dark color scheme as the default and only theme, with colors derived from Insomnia's default dark theme.

#### Scenario: App launches
- **WHEN** the app starts
- **THEN** the entire interface renders in dark mode with a `#2C2C2C` sidebar background, `#292929` pane background, `#ddd` default text, and `#999` highlight color

#### Scenario: Status colors
- **WHEN** the system displays success, warning, danger, or surprise indicators
- **THEN** it uses `#7ecf2b` (success/green), `#ff9a1f` (warning/orange), `#ff5631` (danger/red), and `#a896ff` (surprise/purple)

### Requirement: No Material elevation or shadows
The system SHALL NOT use Material elevation, shadows, or rounded card surfaces. Panels SHALL be separated by 1px borders.

#### Scenario: Panel separation
- **WHEN** the sidebar, request pane, and response pane are visible
- **THEN** they are separated by flat 1px borders with no shadows or elevation

### Requirement: Compact desktop density
The system SHALL use compact padding, spacing, and font sizes appropriate for desktop, not mobile.

#### Scenario: Element spacing
- **WHEN** the user views the request editor or sidebar
- **THEN** padding and spacing are tight (4-8px), list items are dense, and font sizes are 13-14px for body text
