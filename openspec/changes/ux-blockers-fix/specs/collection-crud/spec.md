## ADDED Requirements

### Requirement: Users can create collections
The system SHALL provide a visible control in the sidebar to create a new collection.

#### Scenario: User creates a collection
- **WHEN** the user clicks the new-collection button
- **THEN** a dialog prompts for a name and a new empty collection appears in the sidebar

### Requirement: Users can rename collections
The system SHALL show rename and delete action icons when hovering over a collection header.

#### Scenario: User renames a collection
- **WHEN** the user hovers over a collection header and clicks the rename icon
- **THEN** a dialog with the current name appears and saving updates the collection

### Requirement: Users can delete collections
The system SHALL provide a delete action icon on collection header hover, with confirmation.

#### Scenario: User deletes a collection
- **WHEN** the user hovers over a collection header and clicks the delete icon
- **THEN** a confirmation dialog appears and confirming removes the collection
