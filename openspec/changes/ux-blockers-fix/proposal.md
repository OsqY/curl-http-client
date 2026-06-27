# Proposal: Fix Immediate UX Blockers

## Problem

After the Insomnia-style UI redesign, several critical UX blockers appeared:

1. Console is flooded with `ListTile` warnings about invisible ink splashes.
2. Users cannot easily discover how to edit the request title — it's buried in the Settings tab.
3. There is no visible way to create a new collection.
4. There is no visible way to create or edit an environment.
5. Interactive elements do not show a hand/pointer cursor on desktop, making the app feel less native.

## Goal

Resolve these blockers with minimal, focused changes so the app feels complete enough for daily use.

## Scope

In scope:
- Replace sidebar `ListTile` usage with custom flat rows to eliminate warnings.
- Add a visible, editable request title in the request pane header.
- Add collection CRUD (create, rename, delete) in the sidebar.
- Add environment CRUD (create, edit, delete) in the sidebar.
- Add `SystemMouseCursors.click` to all interactive desktop elements.

Out of scope:
- Drag-and-drop reordering
- Folders CRUD
- Right-click context menus (can be added later)
- Theming changes beyond what's needed for these fixes

## Success criteria

- No `ListTile` warnings in the console.
- A new user can figure out how to rename a request without being told.
- A new user can create a collection and an environment from the sidebar.
- Hovering over buttons, tabs, sidebar rows, and the URL bar shows a pointer cursor.
- All existing tests still pass.
