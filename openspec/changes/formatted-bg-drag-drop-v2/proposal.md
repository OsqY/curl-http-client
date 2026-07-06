# Proposal: Fix formatted response white background on dark theme + desktop drag-and-drop

## Why

Two regressions shipped in v1.1.0:

1. **Formatted response tab shows white background on dark theme.** When viewing a JSON/XML response in the "Formatted" tab, the code block renders with a white background instead of the Soot dark background (`#0C0C0E`). Only the "Raw" and "Headers" tabs respect the theme. The highlight code is unreadable on dark theme.

2. **Drag-and-drop of requests between collections still does not work.** Even after fixing `collectionId` population in v1.1.1, a long-press drag on a request row does not trigger the drag action. The `LongPressDraggable` never activates because the competing `InkWell.onTap` wins the gesture arena first.

## Root Causes

### Bug 1 — White background in Formatted tab

- `lib/ui/widgets/response_panel.dart` line 143 wraps `TabBarView` in `Container(color: colors.bg)`.
- The Formatted tab renders `_VirtualBody` which contains:

  ```dart
  Container(color: widget.colors.bg, child: HighlightView(...))
  ```

- The `HighlightView` widget from `flutter_highlight` 0.7.0 renders its own internal Container. It reads `theme['root']?.backgroundColor` for the background color.
- `sootSyntaxTheme` in `lib/ui/theme/app_theme.dart` does NOT include a `'root'` key with `backgroundColor`. When the key is absent, `HighlightView` uses its fallback background (transparent or white from context).
- The outer `Container(color: colors.bg)` does NOT override the child's internal background because `HighlightView` paints its own opaque background on top.

### Bug 2 — Drag-and-drop doesn't activate

- `LongPressDraggable<HttpRequest>` (lines 474 and 381 of `sidebar.dart`) wraps `SidebarRow`.
- `SidebarRow` (in `lib/ui/widgets/sidebar_row.dart`) contains `GestureDetector(onSecondaryTapDown)` + `InkWell(onTap)`.
- Flutter's gesture arena pits `LongPressGestureRecognizer` (inside LongPressDraggable) against `TapGestureRecognizer` (inside InkWell).
- On desktop with mouse: a click-down + release fires `InkWell.onTap` and the long-press never activates because the GestureArena resolves in favor of the TapGestureRecognizer for short clicks. The user must hold for 500ms, but even then the gesture arena may not reliably award the drag to `LongPressDraggable` when the `InkWell` already claimed the pointer.
- Result: dragging never starts; request rows only respond to clicks (select) and right-clicks (context menu).

## What Changes

- Add `'root': TextStyle(backgroundColor: colors.bg)` to `sootSyntaxTheme` and `sootLightSyntaxTheme` in `app_theme.dart` so `HighlightView` renders its own background matching the theme. No need for the outer Container wrapper in `_VirtualBody` (keep it as belt-and-suspenders).
- Replace `LongPressDraggable<HttpRequest>` with `Draggable<HttpRequest>` in `sidebar.dart` for both root and folder request rows. `Draggable` activates on a natural click-drag (mouse down + move), which is the expected desktop interaction.
- Wrap the `Draggable` in a `GestureDetector(onTap)` to preserve click-to-select behavior without the gesture arena conflict (tap and drag use different gesture recognizers when separated at different widget levels).
- Add `hitTestBehavior: HitTestBehavior.translucent` on the Draggable so the underlying tap GestureDetector can receive taps.

## Impact

- Affected files: `lib/ui/theme/app_theme.dart`, `lib/ui/widgets/sidebar.dart`.
- Affected behavior: response body rendering (all themes), request drag-and-drop (Linux/Windows).
- Users: anyone using dark theme (default) viewing formatted responses; anyone trying to move requests between collections.

## Non-Goals

- No touch-device behavior change (app targets desktop only).
- No Draggable in sidebar ListView (scrolling remains via mouse wheel).
- No architectural refactors to the response panel.
- No changes to the Raw/Headers tabs or the body editor.
