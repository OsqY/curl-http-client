# Soot Theme — Remaining Work Plan

Updated: 2026-07-04

---

## Completed (All Phases)

| Phase | Status | Details |
|---|---|---|
| Phase 1 — Theme Consistency | ✅ | All 9 widgets converted to dynamic colors |
| Phase 2 — UX Polish | ✅ | ClickCursor, theme persistence |
| Phase 3 — Features | ✅ | LICENSE, README |
| Phase 4 — Final Polish | ✅ | sootSyntaxTheme, settings tab, cleanup |
| Phase 5 — Dynamic Syntax + Search | ✅ | Dynamic syntax theme |
| Phase 6 — Technical Debt | ✅ | DropdownMenu migration, light syntax, tests |

## Remaining Issues (Low Priority)

| # | Issue | Effort | Notes |
|---|---|---|---|
| 1 | Sidebar refactor (866 lines) | High | Dialog extraction was fragile, keep as-is |
| 2 | Full widget test suite | Medium | Basic tests added, comprehensive suite needs more work |
| 3 | Window title edge cases | Low | Currently updates on build, could debounce |
| 4 | History search field | Low | UI present, filter logic not implemented |

## Architecture Summary

```
lib/ui/
  theme/app_theme.dart     — AppColors, ColorSet, colorSetProvider,
                              sootSyntaxTheme(), sootLightSyntaxTheme()
  screens/main_screen.dart — Main layout, keyboard shortcuts, window title
  widgets/
    sidebar.dart           — Collections tree, history, env selector, theme switcher
    request_editor.dart    — URL bar, method selector, 6 tabs including settings
    response_panel.dart    — Response body, headers, diff viewer, dynamic syntax
    method_badge.dart      — Colored HTTP method badges
    status_tag.dart        — Status code display
    body_editor.dart       — Request body editor (DropdownMenu)
    auth_editor.dart       — Authentication config (DropdownMenu)
    key_value_editor.dart  — Headers/params editor
    scripts_editor.dart    — Pre/post request scripts
    collection_header.dart — Collection tree header
    sidebar_row.dart       — Sidebar list item
    section_header.dart    — Section labels
    click_cursor.dart      — Pointer cursor wrapper
```
