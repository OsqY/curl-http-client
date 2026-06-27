## Why

The current UI uses default Material 3 with a blue seed color, which looks like a mobile app ported to desktop rather than a native developer tool. For a Bruno/Postman-like HTTP client, the interface should feel like Insomnia: dark, compact, dense, with a three-pane layout, monospace code fields, colored HTTP method badges, and flat panels separated by subtle borders instead of Material elevation.

## What Changes

- Replace the default Material light/dark theme with a custom dark-only theme matching Insomnia's default dark palette.
- Restructure the layout to Insomnia's three-pane model: sidebar (collections/environments), request pane (top), response pane (bottom) — side-by-side with the sidebar, and request/response stacked vertically.
- Replace the `NavigationRail` with a proper sidebar tree view for collections, environments, and history.
- Style the URL bar as a single horizontal bar with a colored method badge, URL input, and Send button.
- Replace Material tabs with flat IDE-style tabs for request configuration (Params, Headers, Auth, Body, Scripts).
- Style the response panel with status/time/size tags, flat tab bar, and syntax-highlighted body.
- Use monospace fonts for URLs, headers, body content, and scripts.
- Apply Insomnia's color semantics: green for GET/success, yellow for POST/notice, orange for PUT/warning, red for DELETE/danger, purple for PATCH/surprise.
- Remove Material elevation/shadows; use 1px borders between panels.
- Compact all padding and spacing to desktop density.

## Capabilities

### New Capabilities

- `dark-theme`: Custom dark color scheme matching Insomnia's default dark palette, applied app-wide.
- `insomnia-layout`: Three-pane layout with sidebar, request pane, and response pane arranged like Insomnia.
- `method-badges`: Colored HTTP method badges in the URL bar and sidebar.
- `ide-style-tabs`: Flat, compact tab bars for request configuration and response viewing.
- `monospace-fields`: Monospace fonts for all code-like text fields (URL, headers, body, scripts, response).

### Modified Capabilities

- None (these are new visual capabilities layered on top of existing functionality).

## Impact

- `lib/ui/app.dart` — theme definition.
- `lib/ui/screens/main_screen.dart` — full layout restructure and widget styling.
- `lib/ui/widgets/` — new widget files for sidebar tree, method badge, tab bar, status tags.
- `pubspec.yaml` — possibly add a monospace font or use system monospace.
- No changes to models, services, repositories, or providers.
