## ADDED Requirements

### Requirement: Users can create folders
The system SHALL provide a control to add a folder to a collection.

#### Scenario: User creates a folder
- **WHEN** the user opens a collection's context menu and selects "New Folder"
- **THEN** a dialog prompts for a folder name and the folder appears under the collection

### Requirement: Users can rename folders
The system SHALL allow renaming a folder via its context menu.

#### Scenario: User renames a folder
- **WHEN** the user right-clicks a folder and selects "Rename"
- **THEN** a dialog with the current name appears and saving updates the folder

### Requirement: Users can delete folders
The system SHALL allow deleting a folder via its context menu, with confirmation.

#### Scenario: User deletes a folder
- **WHEN** the user right-clicks a folder and selects "Delete"
- **THEN** a confirmation dialog appears and confirming removes the folder

### Requirement: Folders are stored in the collection model
The system SHALL persist folder changes inside the collection's JSON file.
