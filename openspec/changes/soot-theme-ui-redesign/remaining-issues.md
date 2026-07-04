# Soot Theme — Remaining Work Plan

Updated: 2026-07-04

---

## Completed

| Phase | Status | Details |
|---|---|---|
| Phase 1 — Theme Consistency | ✅ | All 9 widgets converted to dynamic colors |
| Phase 2 — UX Polish | ✅ | ClickCursor, theme persistence |
| Phase 3 — Features | ✅ | LICENSE, README |
| Phase 4 — Final Polish | ✅ | sootSyntaxTheme, settings tab, cleanup |
| Phase 5 — Dynamic Syntax + Search | ✅ | Dynamic syntax theme, history search field |

## Remaining Issues

### Low Priority (optional improvements)

| # | Issue | Effort | Notes |
|---|---|---|---|
| 1 | DropdownButtonFormField centered | High | Flutter limitation — would need DropdownMenu migration |
| 2 | Sidebar dialog extraction | Medium | 787 lines, could extract 10+ dialog methods |
| 3 | Request search/filter in history | Low | Search field added but filter logic not implemented |
| 4 | Keyboard shortcuts help | Low | Ctrl+Enter/S exist but not discoverable |
| 5 | Request drag-and-drop reorder | High | Not implemented |
| 6 | Request favorites/bookmarks | Low | Not implemented |
| 7 | Window title updates | Low | Always shows "HTTP Client" |

## Architecture Summary

```
lib/ui/
  theme/app_theme.dart     — AppColors, ColorSet, colorSetProvider, sootSyntaxTheme()
  screens/main_screen.dart — Main layout, request/response split
  widgets/
    sidebar.dart           — Collections tree, history, env selector, theme switcher (787 lines)
    request_editor.dart    — URL bar, method selector, 6 tabs including settings
    response_panel.dart    — Response body, headers, diff viewer
    method_badge.dart      — Colored HTTP method badges
    status_tag.dart        — Status code display
    body_editor.dart       — Request body editor
    auth_editor.dart       — Authentication config
    key_value_editor.dart  — Headers/params editor
    scripts_editor.dart    — Pre/post request scripts
    collection_header.dart — Collection tree header
    sidebar_row.dart       — Sidebar list item
    section_header.dart    — Section labels
    click_cursor.dart      — Pointer cursor wrapper
```
