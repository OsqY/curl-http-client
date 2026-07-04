# Soot Theme — Remaining Work Plan

Updated: 2026-07-04

---

## Completed

| Phase | Status | Details |
|---|---|---|
| Phase 1 — Theme Consistency | ✅ DONE | All 9 widgets converted from AppColors.* to colors.X via colorSetProvider |
| Phase 2 — UX Polish | ✅ DONE | ClickCursor on close buttons, theme persistence with shared_preferences |
| Phase 3 — Features | ✅ DONE | MIT LICENSE, updated README for Soot theme |
| Phase 4 — Final Polish | ✅ DONE | sootSyntaxTheme, settings tab, cleanup |

## Remaining Issues

### Low Priority

| # | Issue | Effort | Notes |
|---|---|---|---|
| 1 | DropdownButtonFormField opens centered | High | Flutter limitation — would need migration to DropdownMenu (Material 3). Low user impact. |
| 2 | ClickCursor on DropdownButtonFormField | Medium | 5 dropdowns — wraps are fragile, low visual impact since dropdowns already have visual hover state |
| 3 | sidebar.dart refactoring (787 lines) | Medium | Could extract dialog methods to separate file for maintainability |
| 4 | Syntax theme doesn't change with light mode | Low | sootSyntaxTheme uses dark accent colors even in light mode — would need dynamic syntax map |
| 5 | Request search/find in history | Medium | No search functionality in sidebar history |
| 6 | Keyboard shortcuts help | Low | Ctrl+Enter (send) and Ctrl+S (save) exist but not discoverable |
| 7 | Request drag-and-drop reorder | High | Not implemented |
| 8 | Request favorites/bookmarks | Low | Not implemented |

### Technical Debt

| # | Issue | Effort | Notes |
|---|---|---|---|
| 9 | Theme persistence only saves variant index | Low | Could also save custom colors in future |
| 10 | No error boundaries | Low | FlutterError.onError not set |
| 11 | No window title updates | Low | Window title always shows "HTTP Client" |
