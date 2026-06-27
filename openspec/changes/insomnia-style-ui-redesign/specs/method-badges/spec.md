## ADDED Requirements

### Requirement: HTTP methods are displayed as colored badges
The system SHALL render HTTP method names as colored badges with semantic colors: GET (green), POST (yellow), PUT (orange), PATCH (purple), DELETE (red), HEAD (blue), OPTIONS (blue).

#### Scenario: Method badge in URL bar
- **WHEN** the user selects GET as the method
- **THEN** a green badge with white text "GET" appears at the left of the URL bar

#### Scenario: Method badge in sidebar
- **WHEN** a request appears in the sidebar tree
- **THEN** its method is shown as a small colored badge to the left of the request name

#### Scenario: Method badge colors
- **WHEN** the user changes the method
- **THEN** the badge color updates: GET=#7ecf2b, POST=#f0e137, PUT=#ff9a1f, PATCH=#a896ff, DELETE=#ff5631, HEAD=#46c1e6, OPTIONS=#46c1e6
