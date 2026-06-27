## Context

The request editor (`_RequestEditorState` in `main_screen.dart`) uses `TextEditingController` instances for the URL, name, body, and script fields. On every `build()` call, the controllers' `.text` property is set from the Riverpod `currentRequestProvider` state. Since `onChanged` on each `TextField` writes back to the provider, this creates a feedback loop:

```
User types char → onChanged → provider state updates → rebuild → controller.text = state → cursor resets
```

The `TextEditingController.text =` setter replaces the entire text and collapses the selection to the end (or selects all in some Flutter versions), causing the next keystroke to overwrite.

## Goals / Non-Goals

**Goals:**
- Eliminate the text-overwrite bug in all request editor text fields.
- Preserve cursor position and selection during typing.
- Still update fields when switching to a different request.

**Non-Goals:**
- Redesigning the UI (separate change).
- Changing the state management approach.
- Adding undo/redo support.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Sync strategy | Track last-seen request ID; only update controllers when ID changes | Simplest fix. Avoids controller resets during normal typing. The `onChanged` callback already keeps state in sync, so the controller is the source of truth during editing. |
| Where to track | Store `_lastRequestId` as a field in `_RequestEditorState` | Keeps the fix localized to the stateful widget. |
| Controller update method | Use `controller.value = TextEditingValue(text: ..., selection: TextSelection.collapsed(offset: text.length))` | Sets text and places cursor at end, which is the expected behavior when loading a new request. |
| Key-value editors | Check if `_KeyValueEditor` and `_AuthEditor` have the same issue | These use `TextEditingController(text: item.key)` inline in `build()`, creating a new controller each rebuild. This is also buggy but less severe (fields are short). Fix by using `initialValue` or tracking state. |

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| If the same request object is mutated externally (not via typing), the field won't update. | Acceptable — external mutations always create a new request via `copyWith`, which changes the ID or we can compare by reference. |
| Key-value editors create new controllers per build, which can lose focus. | Address in the same fix by using `initialValue` instead of `controller` for those fields, or by making them stateful. |
