# Tasks: Release gray-screen fix + drag-and-drop + sidebar overflow

## 1. Release-safe bootstrap (Bug 1 — gray screen)

- [ ] 1.1 Read `lib/main.dart` and confirm bare `runApp` with no `ensureInitialized` / `windowManager` init / error handlers.
- [ ] 1.2 Rewrite `lib/main.dart` to: `WidgetsFlutterBinding.ensureInitialized()`, `await windowManager.ensureInitialized()`, set `WindowOptions(title, size, minSize)`, `await windowManager.waitUntilReadyToShow(opts, () => await windowManager.show())`, install `FlutterError.onError`, `ErrorWidget.builder`, wrap `runApp` in `runZonedGuarded`.
- [ ] 1.3 Add a small `ErrorFallback` widget (visible text on init throw) so the app never renders a plain gray screen again.
- [ ] 1.4 Verify `flutter_riverpod` version in `pubspec.yaml`; if `2.6.1` reproduces `No ProviderScope found` in AOT, pin to a known-stable release and document the reason.
- [ ] 1.5 `dart analyze lib/` clean. `flutter analyze` clean.

## 2. Sidebar overflow fix (Bug 2 — RenderFlex overflow)

- [ ] 2.1 Read `lib/ui/widgets/collection_header.dart` Row layout; confirm trailing hover `IconButton`s are not wrapped in `Flexible`.
- [ ] 2.2 Wrap the hover action cluster (`add`/`edit`/`delete`) in `Flexible` (or a `LayoutBuilder` that hides them when `maxWidth < 140`), so the `Expanded(Text)` can shrink freely without overflow.
- [ ] 2.3 Confirm `Expanded(Text)` still uses `overflow: TextOverflow.ellipsis`.
- [ ] 2.4 Keep `_sidebarWidth.clamp(0, 400)` in `lib/ui/screens/main_screen.dart` (collapse-to-0 stays). Optionally bump min to a small value (e.g. 48) only if overflow persists — default keep 0.
- [ ] 2.5 `dart analyze lib/` clean. Drag sidebar to 0px and back; no overflow warnings in console.

## 3. Drag-and-drop reliability (Bug 3 — requests not moving)

- [ ] 3.1 Read `_moveRequest` in `lib/ui/widgets/sidebar.dart`; confirm it `saveRequest(updated, newCollectionId)` then conditionally `deleteRequest(request, oldCollectionId)`.
- [ ] 3.2 Fix `_moveRequest` to ALWAYS delete from the old location: capture `oldCollectionId` and `oldParentFolderId` before copy; if `request.collectionId` is `null`, scan collections to find the existing file before deleting.
- [ ] 3.3 (Preferred) Add `WorkspaceRepository.moveRequest(request, oldCollectionId, newCollectionId, {newFolderId})` that resolves both file paths and does an atomic `File.rename` (or save-then-delete) server-side, returning success/failure. Update sidebar to call it instead of the manual two-step.
- [ ] 3.4 Verify `loadAllRequests` in `workspace_repository.dart` does not double-count requests that have `parentFolderId` set (root list already filters in sidebar UI; ensure repository semantics are coherent — folder children via `loadRequestsForCollection`, root children via `loadAllRequests` minus folder children).
- [ ] 3.5 Verify both root-level and folder-level request rows are wrapped in `LongPressDraggable<HttpRequest>` (sidebar lines 474 and 381). Verify collection header and folder row are `DragTarget<HttpRequest>`.
- [ ] 3.6 After a successful move, call `collectionsProvider.notifier.load()` and confirm the request disappears from the old location and appears in the new one on disk and in the tree.
- [ ] 3.7 `dart analyze lib/` clean.

## 4. CI smoke test (Bug 1 regression guard)

- [ ] 4.1 Read `.github/workflows/build.yml`; add a Linux smoke step after the build: install `xvfb`, run `xvfb-run ./build/linux/x64/release/bundle/http_client` with `timeout 10`, grep output for `No ProviderScope found` and fail the job if present, OR fail if exit code is non-zero before timeout (timeout = success here).
- [ ] 4.2 Confirm the Windows build step has no `ensureInitialized`-blocking artifacts (it should "just work" once main.dart is fixed).
- [ ] 4.3 Trigger a release build (`v1.1.1`) only after tasks 1–3 are verified on a local build.

## 5. Verification & release

- [ ] 5.1 Local build: `flutter build linux --release`; run `./build/linux/x64/release/bundle/http_client`; expect a rendered window with the Soot theme.
- [ ] 5.2 Local smoke: drag sidebar 0 ↔ 400 px; long-press a request and drop on another collection + on a folder; verify move on disk.
- [ ] 5.3 `dart analyze lib/` and `flutter analyze` both clean.
- [ ] 5.4 Tag `v1.1.1`, build, smoke-test the artifact locally BEFORE uploading, then publish the GitHub release with Windows + Linux assets.
