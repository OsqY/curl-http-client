## ADDED Requirements

### Requirement: Collections organize requests
The system SHALL allow users to create collections, each containing a list of requests and optional folders.

#### Scenario: Create a collection
- **WHEN** the user creates a new collection named "Payments API"
- **THEN** the system creates a folder `collections/payments-api/` in the workspace

#### Scenario: Create a folder inside a collection
- **WHEN** the user creates a folder named "v1" inside "Payments API"
- **THEN** the system creates `collections/payments-api/v1/` and requests saved there belong to that folder

### Requirement: Requests are addressable within collections
The system SHALL store each request as a JSON file whose path reflects its collection and folder.

#### Scenario: Save request to nested folder
- **WHEN** the user saves a request named "Create Order" inside "Payments API/v1"
- **THEN** the system writes `collections/payments-api/v1/create-order.json`

### Requirement: Collections support renaming and deletion
The system SHALL allow renaming and deleting collections and folders, updating all child request paths accordingly.

#### Scenario: Rename a collection
- **WHEN** the user renames "Payments API" to "Billing API"
- **THEN** the system renames the directory and updates internal references without data loss
