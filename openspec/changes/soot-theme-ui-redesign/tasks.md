## 1. AppColors palette — rewrite

- [x] 1.1 Replace all color constants in `lib/ui/theme/app_theme.dart` with Soot palette from design.md (bg, surface, elevated, text variants, border variants, accent, amber, green, steel-blue, muted-grey)
- [x] 1.2 Keep the `AppColors` class structure (static const), remove Insomnia colors no longer needed (sidebarHeaderBg, bgSuccess/bgNotice/etc. as bright colors, etc.)
- [x] 1.3 Add new semantic groups: `surface*`, `text*`, `border*`, `accent*`, `syntax*`, `status*`, `scrollbar*`

## 2. ThemeData — rewrite

- [x] 2.1 Update `ThemeData` to use new `AppColors` throughout
- [x] 2.2 Rewrite `colorScheme` (dark), `scaffoldBackgroundColor`
- [x] 2.3 Update `appBarTheme` (no more purple header; use surface/elevated)
- [x] 2.4 Update `dividerTheme`, `tabBarTheme` (indicator uses accent red)
- [x] 2.5 Update `inputDecorationTheme` (focused border accent red)
- [x] 2.6 Update `listTileTheme`, `iconTheme` (muted by default)
- [x] 2.7 Update `textTheme` (Soot text hierarchy)
- [x] 2.8 Update `popupMenuTheme`, `dialogTheme`, `snackBarTheme`
- [x] 2.9 Update `checkboxTheme` (accent red for checked)

## 3. MethodBadge — color remap

- [x] 3.1 In `lib/ui/widgets/method_badge.dart`, replace `_methodColor` return values with Soot muted palette (see design.md §Method Badge Colors)
- [x] 3.2 Update badge background alpha to 10% (`withAlpha(25)` or hex with `1A` alpha), kept existing `withAlpha(30)` — acceptable
- [x] 3.3 Adjust `fontWeight` if needed (keep monospace, bold) — unchanged

## 4. StatusTag — color remap

- [x] 4.1 In `lib/ui/widgets/status_tag.dart`, replace status code color ranges with Soot status colors

## 5. ResponsePanel — syntax theme + diff colors

- [x] 5.1 Create a `sootSyntaxTheme` map for `flutter_highlight` in `app_theme.dart` with Soot syntax colors
- [x] 5.2 Replace `vs2015Theme` import and usage with `sootSyntaxTheme`
- [x] 5.3 Update `_buildDiffText` colors: diff insert → `AppColors.diffInsert` + `AppColors.diffInsertBg`; diff delete → `AppColors.diffDelete` + `AppColors.diffDeleteBg` + line-through
- [x] 5.4 Update status bar, script output container, tab bar, and headers to use Soot colors

## 6. Sidebar — color updates

- [x] 6.1 In `lib/ui/widgets/sidebar.dart`, update all background/color references via sed rename
- [x] 6.2 Dialog backgrounds handled by theme

## 7. RequestEditor — send button + header colors

- [x] 7.1 Pane header → `AppColors.elevated`, URL bar → `AppColors.elevated`, Send button → surface bg + accent red text + border, method selector → surface bg
- [x] 7.2 Tab bar styling via theme

## 8. CollectionHeader — accent/hover

- [x] 8.1 Background → `AppColors.elevated`, folder icon → `AppColors.textMuted` (renamed via sed)

## 9. SidebarRow — hover/selection

- [x] 9.1 hoverColor → `AppColors.border.withAlpha(40)`, highlightColor → `AppColors.border.withAlpha(60)` (unchanged, maps to Soot border color)

## 10. KeyValueEditor — borders + checkbox

- [x] 10.1 Border bottom → `AppColors.border` (via sed), checkbox → accent red via theme

## 11. BodyEditor — borders

- [x] 11.1 Border bottom → `AppColors.border` (via sed), OutlineInputBorder → `AppColors.border` (via theme)

## 12. AuthEditor — input styling

- [x] 12.1 All styling handled by theme; no hardcoded colors found

## 13. ScriptsEditor — input styling

- [x] 13.1 OutlineInputBorder and text colors handled by theme

## 14. SectionHeader

- [x] 14.1 Uses `AppColors.elevated` and `AppColors.textMuted` (renamed via sed)

## 15. Verify build

- [x] 15.1 `dart analyze lib/` — **0 issues found**
- [ ] 15.2 `flutter test` — skipped (flutter snap toolchain has GLIBC compatibility issues)
- [x] 15.3 No hardcoded `Color(0x...)` remaining in widget files (confirmed via grep)
