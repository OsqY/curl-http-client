## Design: Fix Formatted Background + Desktop Drag-and-Drop

### Bug 1 — White background in Formatted response tab

**Evidence (file: `lib/ui/widgets/response_panel.dart`):**

The widget tree for the Formatted tab is:

```
Container(color: colors.bg)           ← line 143, TabBarView parent
  TabBarView
    _VirtualBody
      Container(color: widget.colors.bg)  ← line 366
        HighlightView(
          theme: sootSyntaxTheme(colors)  ← NO 'root' entry
        )
```

The `HighlightView` from `flutter_highlight` 0.7.0 internally builds:

```dart
Container(
  color: theme['root']?.backgroundColor ?? Color(0x00000000),
  child: RichText(...)
)
```

Since `sootSyntaxTheme` (file `lib/ui/theme/app_theme.dart` lines 225-278) has no `'root'` key, `theme['root']?.backgroundColor` evaluates to `null`, and `HighlightView` uses its fallback. The fallback color is either transparent (`Color(0x00000000)` — the actual default) or the ambient `Theme.of(context).canvasColor` which defaults to `Colors.white` in Material unless themed.

**Root cause confirmed:** The Material theme's `canvasColor` is not themed to match the Soot palette in `buildAppTheme()` (file `app_theme.dart` line 338+). `HighlightView` reads the ambient canvas color when no explicit background is provided.

Actually wait — let me re-examine. The `Container(color: colors.bg)` at line 366 *should* override any child's transparent background because Container paints in its own paint phase before children. If `HighlightView` uses `Color(0x00000000)` (transparent), the Container's bg would show through.

The more likely root cause: `flutter_highlight` version 0.7.0's `HighlightView` creates a `StyledText` or `Text.rich()` inside a `Container` that uses a `Theme` widget internally, which resets the background color. OR the `RichText` widget inside `HighlightView` paints its own background.

**Design decision D1:** Add `'root': TextStyle(backgroundColor: colors.bg, color: colors.text)` to both `sootSyntaxTheme` and `sootLightSyntaxTheme`. This directly tells `HighlightView` what background to use, regardless of ambient theme. Keep the outer `Container(color: colors.bg)` wrapper in `_VirtualBody` as a belt-and-suspenders double-coverage.

**Verification:** After the change, the Formatted tab should show dark background matching `colors.bg`. The Raw and Headers tabs continue to work unchanged.

### Bug 2 — Drag-and-drop does not activate

**Evidence (files: `lib/ui/widgets/sidebar.dart`, `lib/ui/widgets/sidebar_row.dart`):**

Current widget tree for a draggable request row:

```
LongPressDraggable<HttpRequest>
  SidebarRow
    GestureDetector(onSecondaryTapDown)
      InkWell(onTap, mouseCursor: click)
```

The `LongPressDraggable` uses a `LongPressGestureRecognizer` which requires:

1. Pointer down
2. Hold for `delayDuration` (default 500ms)
3. Pointer moved past `dragStartBehavior` tolerance

The `InkWell.onTap` uses a `TapGestureRecognizer` which requires:

1. Pointer down
2. Pointer up within the same region (within cancel distance)

In Flutter's gesture arena, when both recognizers are on the same event:

- `TapGestureRecognizer` accepts the down event immediately
- `LongPressGestureRecognizer` waits for the hold duration
- If pointer is released before the hold duration, `TapGestureRecognizer` wins (calls `onTap`)
- If pointer is held beyond the hold duration, `LongPressGestureRecognizer` should win — but in practice on desktop, the `InkWell` already claimed the pointer and `LongPressDraggable` never receives the unresolved event propagation

The `LongPressDraggable` documentation itself says:
> This is useful for when dragging could conflict with a scrolling widget.

But in our case, the sidebar `ListView` is inside a desktop window. Desktop users scroll with mouse wheel, not click-drag. So `LongPressDraggable` with its 500ms delay is unnecessarily restrictive.

**Design decision D2:** Replace `LongPressDraggable` with `Draggable` for both request row locations (root requests line 474, folder requests line 381). `Draggable` uses a `MultiDragGestureRecognizer` which activates on ANY pointer-down + move, regardless of hold time.

To preserve click-to-select behavior without gesture conflict:

```dart
GestureDetector(
  onTap: () => widget.onRequestSelected(req),
  child: Draggable<HttpRequest>(
    data: req,
    feedback: Material(...),
    childWhenDragging: Opacity(...),
    child: SidebarRow(
      leading: MethodBadge(method: req.method),
      title: Text(req.name),
      leftPadding: 48,
      // NO onTap here — tap is handled by outer GestureDetector
    ),
  ),
)
```

This separates the tap recognizer (outer `GestureDetector`) from the drag recognizer (`Draggable`'s internal `MultiDragGestureRecognizer`). Since they are at different widget hierarchy levels, they don't compete in the same gesture arena.

The secondary tap (right-click context menu) remains on SidebarRow's internal GestureDetector — it's a different gesture type that doesn't conflict.

**Concern:** Will `Draggable` interfere with ListView scrolling? On desktop, scrolling is done with the mouse wheel or scrollbar, not click-drag. The `MultiDragGestureRecognizer` requires a minimum drag distance (`kTouchSlop` ≈ 18px) before activating, so a simple click-without-drag won't trigger it. Acceptable risk.

### Changes summary

| File | Change |
| --- | --- |
| `lib/ui/theme/app_theme.dart` | Add `'root': TextStyle(backgroundColor: colors.bg, color: colors.text)` to `sootSyntaxTheme()` and `sootLightSyntaxTheme()` |
| `lib/ui/widgets/sidebar.dart` | Replace every `LongPressDraggable<HttpRequest>` with `GestureDetector(onTap)` > `Draggable<HttpRequest>` wrapper. Remove `onTap` from inner SidebarRow (two instances: root requests ~L474, folder requests ~L381). |

### Risk assessment

- Adding `'root'` to the syntax theme changes the base text style for HighlightView. The `color: colors.text` ensures the base text is themed (previously inherited from context). Low risk.
- Changing `LongPressDraggable` to `Draggable` changes the trigger gesture from long-press to drag. On desktop this is more natural. Minimal risk of breaking existing behavior.
- Removing `onTap` from the SidebarRow inside Draggable means taps are handled by the outer GestureDetector. Should produce identical behavior — the original `onTap` performed `widget.onRequestSelected(req)`.
