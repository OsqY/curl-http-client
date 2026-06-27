## ADDED Requirements

### Requirement: Sidebar supports right-click context menus
The system SHALL show a context menu on right-click for collection headers, folders, and requests in the sidebar.

#### Scenario: User right-clicks a collection
- **WHEN** the user right-clicks a collection header
- **THEN** a menu appears with options: New Folder, Rename, Delete

#### Scenario: User right-clicks a folder
- **WHEN** the user right-clicks a folder
- **THEN** a menu appears with options: New Request, Rename, Delete

#### Scenario: User right-clicks a request
- **WHEN** the user right-clicks a request
- **THEN** a menu appears with options: Duplicate, Rename, Delete

### Requirement: Context menus work on desktop platforms
The system SHALL trigger context menus on secondary click (right-click) for Linux and Windows desktop.
