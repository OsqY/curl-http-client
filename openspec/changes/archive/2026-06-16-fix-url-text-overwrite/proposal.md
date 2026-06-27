## Why

Typing in the URL field (and other text fields in the request editor) causes text to be selected and overwritten on the next keystroke. This makes the app unusable for editing request URLs, headers, body content, and scripts. The root cause is a state-feedback loop: every keystroke updates the Riverpod provider, which rebuilds the widget, which resets the `TextEditingController.text` from state, collapsing the cursor selection.

## What Changes

- Fix the `TextEditingController` sync pattern in `_RequestEditorState` so controllers are only updated when the request changes externally (e.g., selecting a different request from history or collections), not on every build cycle.
- Apply the same fix to all text fields in the request editor: URL, name, body content, pre-request script, and post-response script.
- Preserve cursor position and selection during normal typing.

## Capabilities

### New Capabilities

- `text-field-stability`: Text fields in the request editor SHALL maintain cursor position and selection during user input without being overwritten by state synchronization.

### Modified Capabilities

- None.

## Impact

- `lib/ui/screens/main_screen.dart` — `_RequestEditorState` build method and controller lifecycle.
- No changes to models, services, or providers.
- No breaking changes to persisted data.
