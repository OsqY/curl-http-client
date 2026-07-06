# Design: Release gray-screen fix + drag-and-drop + sidebar overflow

## Root Causes (evidence)

### Bug 1 — Gray screen on release build

Reproduced by running the downloaded bundle:

```
$ cd /home/osqy/Downloads/http-client-linux/bundle && ./http_client
Gdk-Message: Unable to load  from the cursor theme
Bad state: No ProviderScope found
#0  ProviderScope.containerOf (flutter_riverpod/framework.dart:110)
#1  ConsumerStatefulElement._container (flutter_riverpod/consumer.dart:508)
#5  HttpClientApp.build (app.dart:11)  <-- ref.watch(colorSetProvider)
```

- `lib/main.dart` is bare: `void main() { runApp(const ProviderScope(child: HttpClientApp())); }`
  - **Missing**: `WidgetsFlutterBinding.ensureInitialized()`, `await windowManager.ensureInitialized()`, `windowManager.setTitle(...)`, `ErrorWidget.builder`, `FlutterError.onError`, `runZonedGuarded`.
  - In AOT/release mode the lack of `ensureInitialized()` before `runApp` plus the `window_manager` plugin (which needs native channel binding) causes the bootstrap to fail. The invisible error leaves an empty (gray) window.
- `lib/ui/app.dart` `HttpClientApp.build` calls `ref.watch(colorSetProvider)` which, in release mode, throws `No ProviderScope found` because the `ConsumerStatefulElement` cannot resolve the scope from the element tree at the moment of `build` (timing/AOT-specific to flutter_riverpod 2.6.1 + bundled `libapp.so`).
- Bundle integrity is fine: `ldd` shows no `not found`; `data/flutter_assets/` contains `MaterialIcons-Regular.otf`, `FontManifest.json`, `AssetManifest.bin`, shaders, `icudtl.dat`. So it is NOT a missing-asset / missing-lib problem.
- **Why same on Windows**: identical `main.dart` bootstrap → identical throw → identical gray surface.

### Bug 2 — RenderFlex overflow on narrow sidebar

- `lib/ui/screens/main_screen.dart` clamps `_sidebarWidth.clamp(0, 400)` — min width 0.
- `lib/ui/widgets/collection_header.dart` `Row` children: chevron icon + folder icon + `SizedBox(width:6)` + `Expanded(Text)` + (on hover) 3× `IconButton` (add/edit/delete).
- When the sidebar shrinks below the row's intrinsic width, the hover `IconButton`s sit OUTSIDE the `Expanded(Text)` and are not wrapped in `Flexible`, so they push total width past the box → `RenderFlex overflowed by 49–76 px`.
- The `Expanded(Text)` already ellipsizes; the overflow source is the trailing hover actions row.

### Bug 3 — Drag-and-drop does not move requests

Evidence (all present in code):

- `sidebar.dart` has `_moveRequest(...)` (lines 40–57) calling `saveRequest(updated, newCollectionId)` then `deleteRequest(request, request.collectionId!)` then `collectionsProvider.notifier.load()`.
- `CollectionHeader` wraps its content in `DragTarget<HttpRequest>(onAcceptWithDetails: (details) => widget.onRequestDropped!(details.data))` — wired to `_moveRequest(request, collection.id)`. Root-level rows wrapped in `LongPressDraggable<HttpRequest>` (line 474), folder rows wrapped in `LongPressDraggable<HttpRequest>` (line 381).

Critical defect in `_moveRequest`:

```dart
final updated = request.copyWith(collectionId: newCollectionId, parentFolderId: newFolderId);
await repo.saveRequest(updated, newCollectionId);          // writes to NEW location
if (request.collectionId != null) {
  await repo.deleteRequest(request, request.collectionId!);// deletes from OLD location
}
```

- `deleteRequest` uses `request.parentFolderId` (OLD) to find the folder dir — GOOD.
- BUT `saveRequest` writes the file as `${slugify(request.name)}.json`. `deleteRequest` also deletes `${slugify(request.name)}.json`. Since both DerivedName use `request.name` (unchanged by `copyWith`), the save + delete both target a file named by the request name.
  - **Collision risk**: if old and new collection share the same slug-named folder/file, `saveRequest` (new) then `deleteRequest` (old, with OLD `parentFolderId`) is OK.
  - **Real failure**: `loadAllRequests(collection.id)` returns folder children AND root requests, so the `LongPressDraggable` data carries a `request` whose `collectionId`/`parentFolderId` may be `null` in memory (built from JSON without those fields set). When `request.collectionId == null`, the `deleteRequest` branch is **skipped entirely** → the request is duplicated (saved to new location, old file remains). The user perceives "nothing moved".
- Secondary issue: `collectionsProvider.notifier.load()` reloads collections but, due to the duplicate, the request still appears in the old place. To the user drag-and-drop "does nothing".

## Design Decisions

### D1 — Release-safe bootstrap (Bug 1)

Adopt the standard Flutter desktop bootstrap in `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final opts = WindowOptions(size: Size(1400, 900), title: 'HTTP Client');
  await windowManager.waitUntilReadyToShow(opts, () async {
    await windowManager.show();
  });
  FlutterError.onError = (e) => /* log */;
  ErrorWidget.builder = (details) => ErrorFallback(details: details);
  runApp(const ProviderScope(child: HttpClientApp()));
}
```

- Add a small `ErrorFallback` widget so even an init throw renders visible text instead of a gray screen.
- If pinning resolves the AOT Riverpod throw, pin `flutter_riverpod` to a known-stable release (e.g. `^2.5.1`) — verify before pinning.
- Wrap the whole `runApp` body in `runZonedGuarded` as belt-and-suspenders.

### D2 — Overflow-safe CollectionHeader (Bug 2)

- Wrap trailing hover action `IconButton`s inside a `Flexible`/visibility gate, or wrap the whole trailing cluster in `LayoutBuilder` and hide it when `constraints.maxWidth < 140`.
- Keep `Expanded(Text)` ellipsizing the name.
- Set the sidebar `min` clamp from `0` to `0` (keep collapse-to-0 feature) BUT keep header robust to any width.
- Recommended: in `CollectionHeader`, replace `if (_hovering) ...[<IconButtons>]` with `if (_hovering) Flexible(child: Row(children: <IconButtons>))` so the row never overflows.

### D3 — Correct drag-and-drop move (Bug 3)

`_moveRequest` must:

1. Capture OLD `oldCollectionId`, `oldParentFolderId` before copy.
2. Compute `updated = request.copyWith(collectionId: newCollectionId, parentFolderId: newFolderId)`.
3. `await repo.saveRequest(updated, newCollectionId)`.
4. `await repo.deleteRequest(request /* old */, oldCollectionId)` — always, even if `collectionId == null` use the in-memory value or fall back to scanning. (Add `oldCollectionId` param or scan collections to find the source file.)
5. `await collectionsProvider.notifier.load()`.
6. If the dragged `request` lacked a `collectionId` (legacy/legacy JSON), derive it by scanning all collections for a matching file before deletion.

Alternative safer approach: add `moveRequest(request, oldCollectionId, newCollectionId, newFolderId)` to `WorkspaceRepository` that does atomic move by resolving file paths server-side. Safer than the two-step save+delete.

### D4 — CI smoke test (Bug 1 regression guard)

In `.github/workflows/build.yml`, after building, run the Linux binary under `xvfb-run` with a 10s timeout and assert it does NOT print `Bad state: No ProviderScope found` and does NOT exit non-zero before timeout.

## Alternatives Considered

- **Pin riverpod only**: insufficient; the missing `ensureInitialized()` + `window_manager` init is the structural bug. Pinning may mask the symptom but bootstrap remains fragile.
- **Bump min sidebar width to 200**: hides the overflow but does not fix the row's intrinsic overflow; can still break on small windows. Rejected in favor of D2.
- **Reload sidebar via key bump after move**: cosmetic only; does not fix duplicate files on disk.

## Risks

- `window_manager` init ordering: `ensureInitialized` must precede `runApp`. Verified pattern, low risk.
- Changing `_moveRequest` to scan collections on `null` collectionId adds O(N) file reads; acceptable (collections count is small).
- CI `xvfb-run` availability on `ubuntu-latest` — available via `apt-get install xvfb`. Low risk.

## Verification Plan (no implementation yet)

- Run compiled `http_client` from bundle → expect window content (not gray), no `No ProviderScope found`.
- Drag sidebar to 0 → 400 px → no `RenderFlex overflow` in console.
- Long-press a request, drop on another collection header → request file moves; old location empty; tree reloads.
- Drop on a folder row → request goes into the folder subdirectory.
