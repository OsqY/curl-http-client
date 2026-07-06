# Proposal: Release gray-screen fix + drag-and-drop reliability + sidebar overflow fix

## Why

Three release-blocking bugs surfaced after the v1.1.0 release:

1. **Gray screen on Linux release build.** Running the downloaded `http-client-linux.tar.gz` shows only a gray window. The Windows build very likely has the same defect because the root cause is in app initialization, not platform packaging.
   - Reproduced locally: `./http_client` prints `Bad state: No ProviderScope found` and renders nothing.
2. **RenderFlex overflow when collapsing the sidebar.** Dragging the sidebar divider to a narrow width (below ~120px) throws `A RenderFlex overflowed by N pixels on the right` for every collection header row, repeatedly, on every drag update.
3. **Drag-and-drop of requests between collections/folders does not work.** Long-press dragging a request onto a collection header or folder does not move the request. The `_moveRequest` path exists but never fires or fails silently.

## What Changes

- Make the app **release-safe at initialization**: wrap the bootstrap in `WidgetsFlutterBinding.ensureInitialized()`, initialize `window_manager`, install an `ErrorWidget.builder` + `FlutterError.onError` + `runZonedGuarded` so the app never silently shows a gray screen, and pin `flutter_riverpod` to a release-stable version if the `No ProviderScope found` AOT bug is version-specific.
- **Fix the sidebar overflow** so collection headers remain stable for any sidebar width down to 0: wrap the `Row` children in `Flexible`/visibility-gated action buttons and (if needed) skip rendering action buttons below a `LayoutBuilder` width threshold.
- **Fix drag-and-drop** so a long-press drag of a request onto a collection header or folder actually moves the request: correct the `_moveRequest` persistence ordering (save-into-new-location then delete-from-old-location must use the OLD `parentFolderId` for deletion), reload the collection tree, and verify both `LongPressDraggable` (root + folder rows) and `DragTarget` (collection header + folder row) are wired and reachable.
- **Add a CI smoke check** so gray-screen-causing init regressions cannot ship again: a release job that runs the bundled Linux binary headlessly for N seconds and asserts it does not exit with `No ProviderScope found` / non-zero.

## Impact

- Affected files: `lib/main.dart`, `lib/ui/app.dart`, `lib/ui/widgets/collection_header.dart`, `lib/ui/widgets/sidebar.dart`, `lib/repositories/workspace_repository.dart`, `lib/ui/screens/main_screen.dart`, `pubspec.yaml`, `.github/workflows/build.yml`.
- Affected behavior: app startup (all builds), sidebar layout at narrow widths, request organization workflow (drag-and-drop).
- Users: anyone running a v1.1.0+ release binary; anyone organizing requests into folders/collections.

## Non-Goals

- New features (no new tabs, no new providers, no new themes).
- Refactoring sidebar architecture beyond the minimal fixes.
- Changing the workspace on-disk schema.
- Adding network/protocol behavior changes.
- Re-architecting the Riverpod setup beyond the minimal release-safe bootstrap.
