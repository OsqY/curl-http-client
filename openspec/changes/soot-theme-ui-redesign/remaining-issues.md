# Soot Theme — Remaining Work Plan

Generated from thorough codebase scan on 2026-07-04.

---

## Status Summary

| Category | Issues | Severity |
|---|---|---|
| Dynamic Colors (Theme Switching) | 9 widgets using AppColors.* | High |
| Hardcoded Colors | 4 lines in response_panel | Medium |
| ClickCursor Coverage | 3 IconButtons + 5 Dropdowns | Medium |
| Incomplete Features | Settings tab placeholder | Low |
| UI Layout | Dropdown centered positioning | Medium |
| Code Quality | sidebar.dart 787 lines | Low |
| Theme Persistence | Theme resets on restart | Medium |
| Missing Files | No LICENSE, README outdated | Low |

---

## 1. Dynamic Colors — Widgets not switching with theme

**Problem:** 9 widgets still use `AppColors.*` (static dark colors) instead of `colors.X` (dynamic). When switching themes, these widgets don't update.

| Widget | AppColors refs | Priority |
|---|---|---|
| request_editor.dart | 10 | HIGH — visible in URL bar, headers |
| method_badge.dart | 7 | HIGH — visible everywhere |
| status_tag.dart | 4 | HIGH — response status |
| key_value_editor.dart | 1 | MEDIUM — params/headers |
| body_editor.dart | 3 | MEDIUM — body tab |
| scripts_editor.dart | 2 | LOW — scripts tab |
| section_header.dart | 2 | MEDIUM — sidebar section headers |
| sidebar_row.dart | 3 | LOW — hover/select colors |
| collection_header.dart | (not in scan) | LOW — collection header |

**Fix:** For each widget:
1. Add `import 'package:http_client/providers/app_state.dart';`
2. If StatefulWidget → convert to ConsumerStatefulWidget
3. Add `final colors = ref.watch(colorSetProvider);` in build
4. Replace `AppColors.` → `colors.`
5. Remove `const` from widget constructors that use colors

---

## 2. Hardcoded Colors — Diff viewer

**Problem:** response_panel.dart lines 258-263 have hardcoded diff colors:
```dart
DIFF_INSERT => TextStyle(
  backgroundColor: Color(0x4027AE60),  // should be colors.diffInsertBg
  color: Color(0xFF27AE60),             // should be colors.diffInsert
),
DIFF_DELETE => TextStyle(
  backgroundColor: Color(0x40E74C3C),  // should be colors.diffDeleteBg
  color: Color(0xFFE74C3C),             // should be colors.diffDelete
),
```

**Fix:** Replace with `colors.diffInsertBg`, `colors.diffInsert`, `colors.diffDeleteBg`, `colors.diffDelete`.

---

## 3. ClickCursor Coverage

**Problem:** Interactive elements without pointer cursor on desktop.

| File | Line | Element | Missing ClickCursor |
|---|---|---|---|
| key_value_editor.dart | 121 | IconButton (close) | YES |
| body_editor.dart | 171 | IconButton (close) | YES |
| sidebar.dart | 718 | IconButton (visibility) | YES |
| body_editor.dart | 43,56 | DropdownButtonFormField | YES |
| auth_editor.dart | 41,119 | DropdownButtonFormField | YES |
| sidebar.dart | 194 | DropdownButtonFormField | YES |

**Fix:** Wrap each with `ClickCursor(child: ...)`.

---

## 4. Dropdown Positioning

**Problem:** `DropdownButtonFormField` opens its menu centered over the trigger, covering content above and below.

**Flutter limitation:** DropdownButtonFormField doesn't support opening downward. Options:
1. **Migrate to DropdownMenu** (Material 3) — has `alignment` parameter, but changes the API significantly
2. **Custom overlay** — wraps with `CompositedTransformTarget` + manual positioning
3. **Accept the limitation** — keep DropdownButtonFormField, document the behavior

**Recommendation:** Option 3 for now. The centering is Flutter's default behavior and not easily overrideable without major widget refactoring. Document it as a known limitation.

---

## 5. Settings Tab

**Problem:** request_editor.dart line 309 shows "Settings coming soon" placeholder.

**Potential features:**
- Request timeout configuration
- SSL certificate verification toggle
- Default headers
- Proxy configuration
- Theme selection (duplicate sidebar)

**Recommendation:** Keep as placeholder for now, or implement basic settings.

---

## 6. Theme Persistence

**Problem:** Theme selection resets on app restart. `themeVariantProvider` defaults to `SootThemeVariant.dark` every time.

**Fix:** Use `shared_preferences` to persist the selected theme:
```dart
final themeVariantProvider = StateProvider<SootThemeVariant>((ref) {
  // Load from SharedPreferences
  return SootThemeVariant.dark;
});
```

---

## 7. Code Quality

**Problem:** sidebar.dart is 787 lines with many dialog methods mixed in.

**Refactor suggestions:**
- Extract dialog methods to a separate `sidebar_dialogs.dart`
- Extract environment editing to its own widget
- Extract collection management to its own widget

---

## 8. Missing Files

| File | Status |
|---|---|
| LICENSE | Missing — needed for public repo |
| README.md | Exists but references old Insomnia theme |
| .gitignore | Exists |

**Fix:** Add LICENSE (MIT), update README to reference Soot theme.

---

## Execution Priority

### Phase 1 — Theme Consistency (HIGH)
Convert all 9 widgets from AppColors.* to colors.X + fix diff colors.

### Phase 2 — UX Polish (MEDIUM)
Add ClickCursor to remaining elements. Fix theme persistence.

### Phase 3 — Features (LOW)
Settings tab, LICENSE, README update, sidebar refactor.

### Phase 4 — Cleanup (LOW)
Code quality improvements, documentation.
