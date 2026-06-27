## 1. Theme Definition

- [x] 1.1 Create `lib/ui/theme/app_theme.dart` with Insomnia dark palette as a `ThemeData` constant
- [x] 1.2 Define color constants: bgDefault (#2C2C2C), paneBg (#292929), paneHeaderBg (#212121), sidebarHeaderBg (#695eb8), fgDefault (#ddd), highlight (#999), success (#7ecf2b), notice (#f0e137), warning (#ff9a1f), danger (#ff5631), surprise (#a896ff), info (#46c1e6)
- [x] 1.3 Configure `ThemeData` with explicit `colorScheme`, `appBarTheme`, `listTileTheme`, `tabBarTheme`, `dividerTheme`, `inputDecorationTheme`, `textTheme` (monospace for code-like styles)
- [x] 1.4 Set `VisualDensity.compact` as the default density
- [x] 1.5 Update `lib/ui/app.dart` to use the new theme, remove light theme and `ColorScheme.fromSeed`

## 2. Layout Restructure

- [x] 2.1 Replace `NavigationRail` + side-by-side request/response with: `Row` → sidebar (260px) + `Column` → request pane (flex: 1) + `Divider` + response pane (flex: 1)
- [x] 2.2 Remove the separate sidebar panel switching; integrate collections, environments, and history into a single scrollable sidebar with section headers
- [x] 2.3 Add environment selector dropdown at the top of the sidebar
- [x] 2.4 Add 1px borders between sidebar and center column, and between request and response panes

## 3. URL Bar

- [x] 3.1 Create `lib/ui/widgets/method_badge.dart` — colored badge widget for HTTP methods
- [x] 3.2 Replace the `DropdownButtonFormField` + `TextField` + `ElevatedButton` row with a single compact URL bar: method badge (clickable dropdown) + URL input (monospace, no outline border) + Send button (colored)
- [x] 3.3 Style the Send button with the success color (#7ecf2b) background

## 4. Request Configuration Tabs

- [x] 4.1 Style the `TabBar` with flat indicator (bottom border only, no elevation), compact padding (8px horizontal, 6px vertical), 13px font
- [x] 4.2 Style tab content areas with pane background (#292929) and no card elevation
- [x] 4.3 Apply monospace font to key-value editors, body editor, and script editors

## 5. Response Panel

- [x] 5.1 Replace the `Container` status bar with flat status tags: colored status code, time, size — all in a row with pane header background (#212121)
- [x] 5.2 Style response tabs (Body, Headers) with the same flat tab style as request config
- [x] 5.3 Apply monospace font to response body viewer
- [x] 5.4 Style response headers list as dense key-value rows with monospace font

## 6. Sidebar Tree

- [x] 6.1 Create `lib/ui/widgets/collection_tree.dart` — tree view with expandable collections, folders, and requests
- [x] 6.2 Show method badges next to request names in the tree
- [x] 6.3 Add a history section at the bottom of the sidebar with compact entries (method badge + URL + status)
- [x] 6.4 Style the sidebar with sidebar background (#2C2C2C), sidebar foreground (#e0e0e0), and highlight (#999) for hover/selected

## 7. Polish and Verify

- [x] 7.1 Remove all `ElevatedButton` usage; replace with flat `IconButton` or custom buttons
- [x] 7.2 Remove all `Card` and elevation usage; use flat `Container` with borders
- [x] 7.3 Set `debugShowCheckedModeBanner: false` (already done) and remove any remaining Material defaults
- [x] 7.4 Run `flutter test` and `flutter analyze` to ensure no regressions
- [x] 7.5 Build Linux debug and visually verify the layout matches the Insomnia-style mockup
