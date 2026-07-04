# Soot Theme — Remaining Work Plan

Updated: 2026-07-04

---

## Completed

| Phase | Status | Details |
|---|---|---|
| Phase 1 — Theme Consistency | ✅ DONE | All 9 widgets converted from AppColors.* to colors.X via colorSetProvider |
| Phase 2 — UX Polish | ✅ DONE | ClickCursor on close buttons, theme persistence with shared_preferences |
| Phase 3 — Features | ✅ DONE | MIT LICENSE, updated README for Soot theme |

## Remaining Issues

### Priority: Medium

| # | Issue | Effort | Notes |
|---|---|---|---|
| 1 | DropdownButtonFormField opens centered | High | Flutter limitation — would need migration to DropdownMenu (Material 3) |
| 2 | Settings tab placeholder | Medium | Currently shows "Settings coming soon" in request_editor.dart |
| 3 | ClickCursor on DropdownButtonFormField | Low | 5 dropdowns could use ClickCursor wrapper |
| 4 | sidebar.dart refactoring (787 lines) | Medium | Could extract dialog methods to separate file |

### Priority: Low

| # | Issue | Effort | Notes |
|---|---|---|---|
| 5 | Request search/find in history | Medium | No search functionality in sidebar history |
| 6 | Keyboard shortcuts help | Low | Ctrl+Enter (send) and Ctrl+S (save) exist but not discoverable |
| 7 | Request drag-and-drop reorder | High | Not implemented |
| 8 | Request favorites/bookmarks | Low | Not implemented |

### Technical Debt

| # | Issue | Effort | Notes |
|---|---|---|---|
| 9 | Theme persistence only saves variant index | Low | Could also save custom colors in future |
| 10 | Syntax theme doesn't change with light theme | Low | sootSyntaxTheme always uses dark colors even in light mode |
| 11 | No error boundaries | Low | FlutterError.onError not set |
| 12 | No window title updates | Low | Window title always shows "HTTP Client" |
