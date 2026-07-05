# Implementation Plan — Phase 7: UI Polish & Features

## Task Summary

Address user-reported issues and implement requested features:

1. Body responses can't be copied
2. Response panel shows white on dark theme
3. Theme selector / dropdown icons missing cursor pointer
4. Imported requests lost on other actions (need auto-save)
5. History items need hover contrast
6. UI resize / font size controls
7. Resizable panels
8. Body beautifier/formatter

---

## Assumptions

- Flutter desktop (Linux) target, not web
- Riverpod state management
- Existing widget hierarchy: Sidebar → MainScreen → RequestEditor/ResponsePanel
- HighlightView from flutter_highlight for syntax highlighting
- No external packages needed (flutter_highlight already imported)

---

## Files Likely to Change

| File | Changes |
| --- | --- |
| `lib/ui/widgets/response_panel.dart` | Fix white bg, add text selection, diff colors |
| `lib/ui/widgets/sidebar.dart` | History hover contrast, icon cursors |
| `lib/ui/widgets/body_editor.dart` | Beautifier button, layout spacing |
| `lib/ui/widgets/key_value_editor.dart` | Layout spacing |
| `lib/ui/screens/main_screen.dart` | Auto-save on import, panel resize |
| `lib/ui/theme/app_theme.dart` | Theme colors |
| `lib/ui/widgets/sidebar_dialogs.dart` | Dialog styling |

---

## Allowed New File Locations

- `lib/ui/widgets/body_formatter.dart` — JSON/XML formatter widget
- `lib/ui/widgets/resizable_panel.dart` — Resizable panel widget
- `lib/ui/utils/text_selection.dart` — Text selection helper (if needed)

---

## Off-limits Files

- `lib/services/` — No changes to service layer
- `lib/repositories/` — No changes to data persistence
- `lib/models/` — No model changes needed

---

## Implementation Steps

### Step 1: Fix Response Panel White Background

**Problem:** HighlightView has no background color, shows white on dark theme.

**Files:** `lib/ui/widgets/response_panel.dart`

**Changes:**

- Wrap HighlightView in Container with `color: colors.surface` or `color: colors.bg`
- The Container parent already has `color: colors.surface` at line 123, but the HighlightView itself might need explicit background
- Check if flutter_highlight's HighlightView accepts a `backgroundColor` parameter
- If not, wrap in Container with correct bg color

```dart
// Before (line 329):
child: HighlightView(
  pretty,
  language: widget.language,
  theme: ...,
  padding: const EdgeInsets.all(10),
  textStyle: TextStyle(fontFamily: 'monospace', fontSize: 13),
),

// After:
child: Container(
  color: widget.colors.surface,
  child: HighlightView(
    pretty,
    language: widget.language,
    theme: ...,
    padding: const EdgeInsets.all(10),
    textStyle: TextStyle(fontFamily: 'monospace', fontSize: 13),
  ),
),
```

### Step 2: Fix Response Body Text Selection

**Problem:** HighlightView doesn't support text selection/copy.

**Files:** `lib/ui/widgets/response_panel.dart`

**Options:**

- A) Replace HighlightView with SelectableText + RichText (complex, loses syntax highlighting)
- B) Use flutter_highlight's built-in selection if available
- C) Add a "Copy" button that copies the entire body to clipboard
- D) Use SelectionArea widget wrapper around HighlightView

**Recommended: Option D** — Wrap HighlightView in `SelectionArea` widget (Flutter 3.10+)

```dart
// After wrapping in Container:
SelectionArea(
  child: HighlightView(
    pretty,
    language: widget.language,
    theme: ...,
    padding: const EdgeInsets.all(10),
    textStyle: TextStyle(fontFamily: 'monospace', fontSize: 13),
  ),
),
```

### Step 3: Fix Theme Selector / Dropdown Cursor

**Problem:** Icons don't show pointer cursor on hover.

**Files:** `lib/ui/widgets/sidebar.dart`

**Changes:**

- Add `mouseCursor: SystemMouseCursors.click` to PopupMenuButton in sidebar header
- Add `mouseCursor: SystemMouseCursors.click` to DropdownMenu trigger

```dart
// Sidebar header theme selector (line ~49):
ClickCursor(
  child: PopupMenuButton<SootThemeVariant>(
    mouseCursor: SystemMouseCursors.click,  // ADD THIS
    ...
  ),
),
```

### Step 4: Auto-save on Import

**Problem:** Imported request is lost when performing other actions.

**Files:** `lib/ui/screens/main_screen.dart`

**Changes:**

- After `ref.read(currentRequestProvider.notifier).state = request;` in `_importCurl()`, also save to workspace
- Add auto-save logic similar to `_saveRequest()`

```dart
// In _importCurl(), after setting currentRequest:
ref.read(currentRequestProvider.notifier).state = request;
// Auto-save to first collection
final collections = ref.read(collectionsProvider).valueOrNull ?? [];
if (collections.isNotEmpty) {
  await ref.read(workspaceRepositoryProvider)
      .saveRequest(request, collections.first.id);
}
```

### Step 5: History Hover Contrast

**Problem:** History items lack hover feedback.

**Files:** `lib/ui/widgets/sidebar.dart`

**Changes:**

- Add hover effect to SidebarRow in history section
- Use `InkWell` with `hoverColor` or `MouseRegion` with hover color

```dart
// In history ListView.builder itemBuilder:
return MouseRegion(
  cursor: SystemMouseCursors.click,
  child: Container(
    decoration: BoxDecoration(
      // Add hover state via StatefulWidget or AnimatedContainer
    ),
    child: SidebarRow(...),
  ),
);
```

Better approach: Convert SidebarRow to support hover state internally, or add a wrapper widget.

### Step 6: Font Size Controls

**Problem:** No way to change font size.

**Files:** `lib/ui/screens/main_screen.dart`, `lib/ui/widgets/request_editor.dart`, `lib/ui/widgets/body_editor.dart`

**Approach:**

- Add a `fontSizeProvider` to app_state.dart
- Add font size selector in Settings tab or toolbar
- Pass fontSize to all text widgets
- Use `MediaQuery.textScaleFactorOf(context)` or custom provider

```dart
// In app_state.dart:
final fontSizeProvider = StateProvider<double>((ref) => 13.0);

// In request_editor.dart Settings tab:
Row(
  children: [
    Text('Font Size'),
    Slider(
      value: ref.watch(fontSizeProvider),
      min: 10,
      max: 20,
      onChanged: (v) => ref.read(fontSizeProvider.notifier).state = v,
    ),
  ],
)
```

### Step 7: Resizable Panels

**Problem:** Request and response panels have fixed 50/50 split.

**Files:** `lib/ui/screens/main_screen.dart`, new `lib/ui/widgets/resizable_panel.dart`

**Approach:**

- Create a `ResizablePanel` widget with a draggable divider
- Use `GestureDetector` on the divider to detect drag
- Store panel ratio in provider or local state
- Replace the current `Expanded(flex: 1)` with custom split

```dart
// New widget: lib/ui/widgets/resizable_panel.dart
class ResizablePanel extends StatefulWidget {
  final Widget left;
  final Widget right;
  final double initialRatio; // 0.0 to 1.0
  
  const ResizablePanel({
    required this.left,
    required this.right,
    this.initialRatio = 0.5,
  });
  ...
}
```

### Step 8: Body Beautifier/Formatter

**Problem:** No way to format/beautify request bodies.

**Files:** `lib/ui/widgets/body_editor.dart`, new `lib/ui/widgets/body_formatter.dart`

**Approach:**

- Add a "Format" button next to the body mode dropdown
- Implement JSON formatter (jsonDecode + jsonEncode with indent)
- Implement XML formatter (basic indentation)
- Only available for raw mode with JSON or XML content type

```dart
// In body_editor.dart, after the content type dropdown:
Row(
  children: [
    // ... existing dropdown
    Spacer(),
    if (body.mode == BodyMode.raw && body.rawContentType == RawContentType.json)
      IconButton(
        icon: Icon(Icons.code),
        tooltip: 'Format JSON',
        onPressed: () => _formatBody(),
      ),
    if (body.mode == BodyMode.raw && body.rawContentType == RawContentType.xml)
      IconButton(
        icon: Icon(Icons.code),
        tooltip: 'Format XML',
        onPressed: () => _formatBody(),
      ),
  ],
)

void _formatBody() {
  try {
    if (body.rawContentType == RawContentType.json) {
      final parsed = jsonDecode(body.rawContent);
      final formatted = JsonEncoder.withIndent('  ').convert(parsed);
      widget.onChanged(body.copyWith(rawContent: formatted));
    } else if (body.rawContentType == RawContentType.xml) {
      // Basic XML formatting
      final formatted = _formatXml(body.rawContent);
      widget.onChanged(body.copyWith(rawContent: formatted));
    }
  } catch (e) {
    // Show error snackbar
  }
}
```

---

## Risks

| Risk | Mitigation |
| --- | --- |
| SelectionArea might not work with HighlightView | Test thoroughly; fallback to Copy button |
| Panel resize could break layout on small screens | Add minimum panel width constraints |
| Font size changes might break fixed layouts | Use relative sizing, test on multiple sizes |
| XML formatter is basic | Document limitation, offer JSON as primary |
| Auto-save might save incomplete requests | Only save after successful import |

---

## Validation Steps

1. `dart analyze lib/` — 0 issues
2. Manual testing:
   - Send request → verify response body is copyable
   - Switch themes → verify no white backgrounds
   - Hover over theme selector → verify cursor changes
   - Import curl → verify request persists
   - Hover history items → verify contrast change
   - Change font size → verify all text updates
   - Drag panel divider → verify resize works
   - Format JSON body → verify formatting
3. `flutter test` — all tests pass

---

## Rollback Notes

- All changes are in UI layer only
- No service/model changes
- Can revert individual features by reverting specific commits
- Theme changes are backwards-compatible (old themes still work)

---

## Readiness Status

- [ ] Step 1: Response panel background — NOT STARTED
- [ ] Step 2: Text selection — NOT STARTED
- [ ] Step 3: Cursor fixes — NOT STARTED
- [ ] Step 4: Auto-save — NOT STARTED
- [ ] Step 5: Hover contrast — NOT STARTED
- [ ] Step 6: Font size — NOT STARTED
- [ ] Step 7: Panel resize — NOT STARTED
- [ ] Step 8: Body beautifier — NOT STARTED
