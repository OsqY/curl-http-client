## 1. ListTile warnings

- [x] 1.1 Create `_SidebarRow` reusable widget using `InkWell` + `Container` + `Row`, with `MouseRegion(cursor: SystemMouseCursors.click)`
- [x] 1.2 Replace all `ListTile` usages in `_Sidebar` with `_SidebarRow`
- [x] 1.3 Verify no `ListTile` warnings appear in console on app launch

## 2. Request title

- [x] 2.1 Add `_titleController` to `_RequestEditorState`
- [x] 2.2 Sync title controller using `_lastRequestId` guard
- [x] 2.3 Add editable title `TextField` above the URL bar in request pane header
- [x] 2.4 Update request name in provider on `onChanged`

## 3. Collection CRUD

- [x] 3.1 Add `+` icon next to collection section header to create a new collection
- [x] 3.2 Show rename and delete icons on collection header row hover
- [x] 3.3 Implement `_showCollectionNameDialog` for create/rename
- [x] 3.4 Implement delete with confirmation dialog
- [x] 3.5 Wire actions to `collectionsProvider` save/delete

## 4. Environment CRUD

- [x] 4.1 Add `+` and edit icons adjacent to environment dropdown
- [x] 4.2 Add delete option for active environment in a popup menu
- [x] 4.3 Reuse existing environment editor dialog
- [x] 4.4 Wire create/edit/delete to `environmentsProvider` save/delete
- [x] 4.5 Clear active environment when the active one is deleted

## 5. Folder CRUD

- [x] 5.1 Add "New Folder" to collection context menu
- [x] 5.2 Add "Rename" and "Delete" to folder context menu
- [x] 5.3 Implement folder create/rename/delete with dialogs
- [x] 5.4 Persist folder changes via `collectionsProvider.save`

## 6. Right-click context menus

- [x] 6.1 Implement `_showContextMenu` helper for desktop secondary click
- [x] 6.2 Add collection context menu: New Folder, Rename, Delete
- [x] 6.3 Add folder context menu: New Request, Rename, Delete
- [x] 6.4 Add request context menu: Duplicate, Rename, Delete

## 7. Duplicate request

- [x] 7.1 Add "Duplicate" action to request context menu
- [x] 7.2 Implement duplication: copy fields, new ID, "(copy)" suffix
- [x] 7.3 Set duplicated request as active request

## 8. Click cursor

- [x] 8.1 Add `MouseRegion` with `SystemMouseCursors.click` to `_SidebarRow`
- [x] 8.2 Add `MouseRegion` to URL bar method badge dropdown, Send button, Save button
- [x] 8.3 Add `MouseRegion` to request/response `TabBar` labels via theme or wrapper
- [x] 8.4 Add `MouseRegion` to New Request button, collection header icons, env selector icons
- [x] 8.5 Ensure text fields keep `SystemMouseCursors.text`

## 9. Verify

- [x] 9.1 Run `flutter test` — all pass
- [x] 9.2 Run `flutter analyze` — no errors
- [x] 9.3 Run app and confirm console is clean
- [x] 9.4 Manually test title editing, collection/folder CRUD, environment CRUD, duplicate request, context menus
