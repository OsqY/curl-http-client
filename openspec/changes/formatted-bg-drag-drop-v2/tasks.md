# Tasks: Fix Formatted Background + Desktop Drag-and-Drop

## 1. Fix HighlightView background in sootSyntaxTheme

- [ ] 1.1 Read `lib/ui/theme/app_theme.dart` lines 225–290. Confirm `sootSyntaxTheme` and `sootLightSyntaxTheme` maps.
- [ ] 1.2 Add `'root': TextStyle(backgroundColor: colors.bg, color: colors.text)` as the first entry in `sootSyntaxTheme(Map)`.
- [ ] 1.3 Add `'root': TextStyle(backgroundColor: colors.bg, color: colors.text)` as the first entry in `sootLightSyntaxTheme(Map)`.
- [ ] 1.4 Run `dart analyze lib/` — 0 issues.
- [ ] 1.5 Verify the Formatted tab in the response panel renders with the theme background (not white) by building and testing.

## 2. Replace LongPressDraggable with Draggable for desktop

- [ ] 2.1 Read `lib/ui/widgets/sidebar.dart` and locate the two `LongPressDraggable<HttpRequest>` instances (root requests ~line 474, folder requests ~line 381).
- [ ] 2.2 For root requests (line ~474): replace `LongPressDraggable<HttpRequest>` block with:

  ```dart
  GestureDetector(
    onTap: () => widget.onRequestSelected(req),
    child: Draggable<HttpRequest>(
      data: req,
      feedback: Material(elevation: 4, borderRadius: BorderRadius.circular(4),
        child: Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: colors.elevated, borderRadius: BorderRadius.circular(4)),
          child: Row(mainAxisSize: MainAxisSize.min,
            children: [MethodBadge(method: req.method), SizedBox(width: 8),
              Text(req.name, style: TextStyle(color: colors.text, fontSize: 12))],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: SidebarRow(...)),
      child: SidebarRow(
        leading: MethodBadge(method: req.method),
        title: Text(req.name, style: TextStyle(fontSize: 12)),
        leftPadding: 24,
        // NO onTap — handled by outer GestureDetector
        onSecondaryTap: () => dialogs.showRequestContextMenu(context, collection, req),
      ),
    ),
  )
  ```

- [ ] 2.3 For folder requests (line ~381): apply the same pattern — wrap in `GestureDetector(onTap)` / `Draggable<HttpRequest>` / remove `onTap` from inner SidebarRow.
- [ ] 2.4 Run `dart analyze lib/` — 0 issues.
- [ ] 2.5 Build locally and test: click-drag a request onto another collection header and onto a folder.

## 3. Verification

- [ ] 3.1 `dart analyze lib/ test/` clean.
- [ ] 3.2 Local build: `flutter build linux --release`.
- [ ] 3.3 Test gray screen is still fixed (regression check).
- [ ] 3.4 Test Formatted tab renders with dark background.
- [ ] 3.5 Test drag-and-drop: click-drag a request → other collection → request moves correctly.
- [ ] 3.6 Test drag-and-drop to folder.
- [ ] 3.7 Tag `v1.1.2` and publish release.
