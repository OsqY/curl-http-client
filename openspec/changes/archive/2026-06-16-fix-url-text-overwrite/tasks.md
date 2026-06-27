## 1. Fix Controller Sync in Request Editor

- [x] 1.1 Add `_lastRequestId` field to `_RequestEditorState` to track the currently-loaded request ID
- [x] 1.2 Guard the controller text updates in `build()` to only run when `request.id != _lastRequestId`, then update `_lastRequestId`
- [x] 1.3 Use `TextEditingValue(text: ..., selection: TextSelection.collapsed(offset: ...))` when setting controller text to place cursor at end
- [x] 1.4 Verify URL, name, body, pre-request script, and post-response script fields all preserve cursor during typing

## 2. Fix Key-Value and Auth Editor Controllers

- [x] 2.1 Replace inline `TextEditingController(text: ...)` in `_KeyValueEditor` with `initialValue` parameter or stateful controllers
- [x] 2.2 Replace inline `TextEditingController(text: ...)` in `_AuthEditor` with `initialValue` parameter or stateful controllers
- [x] 2.3 Replace inline `TextEditingController(text: ...)` in `_BodyEditor` raw content field with proper controller management
- [x] 2.4 Replace inline `TextEditingController(text: ...)` in `_ScriptsEditor` with proper controller management

## 3. Verify

- [x] 3.1 Manually test typing a URL character by character without text being selected
- [x] 3.2 Manually test editing the middle of a URL
- [x] 3.3 Manually test switching requests from history and confirming fields update
- [x] 3.4 Run `flutter test` and `flutter analyze` to ensure no regressions
