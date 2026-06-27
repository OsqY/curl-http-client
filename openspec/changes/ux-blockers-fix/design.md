## Context

The Insomnia-style redesign moved the app to a flat, dark, compact desktop UI. In doing so, it used `ListTile` heavily in the sidebar, which now conflicts with the custom dark backgrounds and produces console warnings. It also removed the previous dedicated environment sidebar and hid the request title in a tab.

## Design decisions

| Decision | Choice | Rationale |
|---|---|---|
| Sidebar rows | Custom `_SidebarRow` widget with `InkWell` + `Container` | Eliminates `ListTile` warnings, full control over hover/selected colors, easy pointer cursor |
| Request title | Inline editable field above the URL bar | Most discoverable, matches Insomnia's pattern, separates naming from request configuration |
| Collection CRUD | Section header with `+` icon; rename/delete icons appear only on hover | Clean default state, actions accessible without clutter |
| Environment CRUD | Dropdown selector with adjacent `+` and edit icons; delete hidden in a menu | Keeps selector compact, prevents accidental deletion |
| Folder CRUD | `+` icon on collection header to add folder; rename/delete via right-click context menu | Folders are secondary, context menu keeps UI minimal |
| Right-click context menus | Desktop-style context menus on sidebar rows | Familiar pattern for rename/delete/duplicate |
| Duplicate request | Context menu item on request rows | Common workflow, avoids manual copy-paste |
| Click cursor | `MouseRegion(cursor: SystemMouseCursors.click, child: ...)` wrapper or inline | Desktop-native feel; not applied to text fields which keep text cursor |

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Sidebar gets crowded with more icons | Keep icons small (16px) and only show on hover or when relevant |
| Request title sync could reintroduce text-overwrite bug | Use same `_lastRequestId` guard pattern already in place |
| Renaming collections via inline edit might conflict with selecting | Use a dedicated dialog or a separate inline mode triggered by an icon |
