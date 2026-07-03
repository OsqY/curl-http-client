## Why

The current UI uses an Insomnia-style dark palette: grey backgrounds (#2C2C2C, #292929), a purple sidebar header (#695EB8), rainbow method colors (bright green POST, yellow POST, orange PUT, red DELETE), and green Send button. It's functional but visually noisy — the purple header dominates, the rainbow accents compete, and the overall feel is "yet another dark IDE skin."

The **Soot theme** (inspired by Nothing Technology's design language) is a deliberate alternative: monochrome-dominant, dot-matrix-inspired, with sparse signal accents. It follows "subtract don't add" — fewer colors, more breathing room, higher signal-to-noise ratio. The Zed extension `soot-theme` already implements this for the editor; this change brings the same philosophy to the HTTP client.

## What Changes

- Replace the entire color palette: from Insomnia greys + purple header + rainbow methods to Soot's near-black background (#0C0C0E), warm dark surfaces (#161618, #1C1C20), and a single signal accent (red #E10F1C).
- Remove the purple sidebar header; replace with a subtle red accent border or minimal header.
- Tame method badge colors: from bright semantic colors to a muted monochrome system with accent only on the selected/active method.
- Replace the rainbow vs2015 syntax highlighting theme in the response panel with a monochrome-dominant Soot syntax scheme (red for keywords, amber for constants, muted green for strings, steel blue for types).
- Update all widget colors, borders, hover states, selection colors, input styles, and dialog backgrounds to match the Soot palette.
- Keep the same layout, widget structure, and behavior — this is a pure reskin of `lib/ui/`.

## Capabilities

### New Capabilities

- `soot-dark-theme`: Full dark-only theme using the Soot palette (near-black bg, warm dark surfaces, red signal accent, monochrome syntax). Applied app-wide.
- `soot-method-badges`: Muted method badges (monochrome by default, accent on selected) instead of bright rainbow colors.
- `soot-syntax-highlighting`: Custom syntax theme for the response body viewer (red keywords, amber constants, muted green strings, steel blue types, grey comments).

### Modified Capabilities

- `dark-theme` (from insomnia-style-ui-redesign): replaced with soot-dark-theme.
- `method-badges`: colors changed from rainbow to monochrome + accent.
- Syntax highlighting in response panel: theme changed from vs2015 to soot.

## Impact

- `lib/ui/theme/app_theme.dart` — full rewrite of AppColors and ThemeData.
- `lib/ui/widgets/method_badge.dart` — color mapping changed.
- `lib/ui/widgets/response_panel.dart` — syntax theme + diff colors + status colors.
- `lib/ui/widgets/status_tag.dart` — status code colors adjusted.
- `lib/ui/widgets/sidebar.dart` — reference colors and collection header style.
- `lib/ui/widgets/request_editor.dart` — send button color, pane header colors.
- `lib/ui/widgets/collection_header.dart` — accent/hover colors.
- `lib/ui/widgets/sidebar_row.dart` — hover/selection colors.
- `lib/ui/widgets/key_value_editor.dart` — border/checkbox colors.
- `lib/ui/widgets/body_editor.dart` — border colors.
- `lib/ui/widgets/auth_editor.dart` — input colors.
- `lib/ui/widgets/scripts_editor.dart` — input colors.
- `lib/ui/widgets/section_header.dart` — color references.
- No changes to models, services, repositories, or providers.
- No changes to layout, widget structure, or business logic.

## Files Changed

```
lib/ui/theme/app_theme.dart         — full rewrite
lib/ui/widgets/method_badge.dart    — color mapping
lib/ui/widgets/status_tag.dart      — status code colors
lib/ui/widgets/response_panel.dart  — syntax theme + diff colors
lib/ui/widgets/sidebar.dart         — color refs
lib/ui/widgets/request_editor.dart  — send button, pane header
lib/ui/widgets/collection_header.dart — accent colors
lib/ui/widgets/sidebar_row.dart     — hover/selection
lib/ui/widgets/key_value_editor.dart — border colors
lib/ui/widgets/body_editor.dart     — border colors
lib/ui/widgets/auth_editor.dart     — input colors
lib/ui/widgets/scripts_editor.dart  — input colors
lib/ui/widgets/section_header.dart  — color refs
lib/ui/widgets/widgets.dart         — no change needed
lib/ui/app.dart                     — no change needed
lib/ui/screens/main_screen.dart     — no change needed
```
