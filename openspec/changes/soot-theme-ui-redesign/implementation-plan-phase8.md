# Implementation Plan — Phase 8: UI Finale

## Task Summary

Complete remaining UI features:

1. Connect fontSizeProvider to all text widgets
2. Create resizable panels between request/response

---

## Assumptions

- Flutter desktop (Linux) target
- Riverpod state management
- fontSizeProvider already exists in app_state.dart
- main_screen.dart has the split layout (Expanded → request / divider / response)

---

## Step 1 — Connect fontSizeProvider

**Problem:** The font size slider in Settings tab exists but doesn't change any text.

**Files to modify:**

- `lib/ui/widgets/request_editor.dart` — URL bar, headers, tabs, key-value editors
- `lib/ui/widgets/response_panel.dart` — response body, headers, syntax text
- `lib/ui/widgets/body_editor.dart` — body content editor
- `lib/ui/widgets/scripts_editor.dart` — script editors
- `lib/ui/widgets/sidebar.dart` — sidebar text
- `lib/ui/widgets/method_badge.dart` — method badge text
- `lib/ui/widgets/status_tag.dart` — status code text
- `lib/ui/widgets/key_value_editor.dart` — key/value pair text
- `lib/ui/widgets/section_header.dart` — section header text
- `lib/ui/widgets/collection_header.dart` — collection name text

**Approach:**
Each ConsumerWidget already has `ref.watch(colorSetProvider)`. Add `final fontSize = ref.watch(fontSizeProvider);` and replace hardcoded `fontSize: 13` with `fontSize: fontSize`.

```dart
// Before:
style: TextStyle(fontSize: 13, color: colors.text)

// After:
style: TextStyle(fontSize: fontSize, color: colors.text)
```

**Estimated changes:** ~80-120 text style modifications across ~10 files.

**Risk:** Low — mechanical change, all caught by dart analyze.

---

## Step 2 — Resizable Panels

**Problem:** Request/response panels have a fixed 50/50 split. User cannot resize.

**Solution:** Add a draggable horizontal divider between the panels.

**File:** `lib/ui/screens/main_screen.dart`

**Current layout (simplified):**

```dart
Column(
  children: [
    Expanded(flex: 1, child: RequestEditor(...)),
    Divider(height: 1, thickness: 1),
    Expanded(flex: 1, child: ResponsePanel()),
  ],
)
```

**New layout:**

```dart
Column(
  children: [
    // Top panel (request)
    SizedBox(
      height: topHeight, // driven by a local state variable
      child: RequestEditor(...),
    ),
    // Draggable divider
    GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          topHeight += details.delta.dy;
          topHeight = topHeight.clamp(200, totalHeight - 200);
        });
      },
      child: Container(
        height: 6,
        cursor: SystemMouseCursors.resizeRow,
        color: colors.border,
      ),
    ),
    // Bottom panel (response)
    Expanded(
      child: ResponsePanel(),
    ),
  ],
)
```

**Key details:**

- Use `LayoutBuilder` to get the total available height
- Store `topHeight` in state or a provider
- Clamp values to prevent panels from disappearing
- Use `SystemMouseCursors.resizeRow` for the cursor

**File to modify:**

- `lib/ui/screens/main_screen.dart`

**Risk:** Medium — involves state changes on drag, need to clamp properly, test edge cases.

---

## Implementation Order

| Step | Files | Effort | Risk | Depends on |
| --- | --- | --- | --- | --- |
| 1. fontSize | 10 files | Medium | Low | fontSizeProvider exists |
| 2. Resizable panels | main_screen.dart | Medium | Medium | — |

---

## Validation

1. `dart analyze lib/` — 0 issues
2. Build and run: `flutter build linux --release`
3. Test font size slider changes all text
4. Test panel divider drag clamps correctly

---

## Rollback

- Step 1 can be reverted per-file
- Step 2: revert `main_screen.dart` to previous commit
