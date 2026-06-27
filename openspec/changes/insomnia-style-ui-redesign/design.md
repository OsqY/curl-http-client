## Context

The app currently uses default Material 3 with a blue seed color, a `NavigationRail` for sidebar navigation, and side-by-side request/response panels. The user wants it to look like Insomnia: dark, compact, three-pane, with colored method badges, flat tabs, monospace code fields, and no Material elevation.

Insomnia's default dark theme uses these colors (extracted from the Kong/insomnia source):

```
┌─────────────────────────────────────────────────────────┐
│              INSOMNIA DEFAULT DARK PALETTE               │
├──────────────┬──────────────┬───────────────────────────┤
│ Role         │ Token        │ Hex                       │
├──────────────┼──────────────┼───────────────────────────┤
│ Background   │ default      │ #2C2C2C                   │
│              │ success      │ #7ecf2b                   │
│              │ notice       │ #f0e137                   │
│              │ warning      │ #ff9a1f                   │
│              │ danger       │ #ff5631                   │
│              │ surprise     │ #a896ff                   │
│              │ info         │ #46c1e6                   │
├──────────────┼──────────────┼───────────────────────────┤
│ Foreground   │ default      │ #ddd                      │
├──────────────┼──────────────┼───────────────────────────┤
│ Highlight    │ default      │ #999                      │
├──────────────┼──────────────┼───────────────────────────┤
│ Sidebar BG   │ default      │ #2C2C2C                   │
│ Sidebar FG   │ default      │ #e0e0e0                   │
├──────────────┼──────────────┼───────────────────────────┤
│ Pane BG      │ default      │ #292929                   │
│ Pane FG      │ default      │ #e0e0e0                   │
├──────────────┼──────────────┼───────────────────────────┤
│ PaneHeader   │ bg default   │ #212121                   │
│              │ fg default   │ #ccc                      │
├──────────────┼──────────────┼───────────────────────────┤
│ SidebarHdr   │ bg default   │ #695eb8                   │
│              │ fg default   │ #fff                      │
├──────────────┼──────────────┼───────────────────────────┤
│ Dialog BG    │ default      │ #2a2a2a                   │
│ Overlay BG   │ default      │ rgba(30,30,30,0.8)        │
└──────────────┴──────────────┴───────────────────────────┘
```

Insomnia's layout:

```
┌──────────┬──────────────────────────────────────────────┐
│          │  [GET ▼] https://api.example.com/users [Send] │
│ Sidebar  │  Params | Headers | Auth | Body | Scripts     │
│          │  ┌─────────────────────────────────────────┐  │
│ Col 1    │  │  key          value                     │  │
│   req 1  │  │  ...                                     │  │
│   req 2  │  └─────────────────────────────────────────┘  │
│          │ ─────────────── divider ─────────────────────  │
│ History  │  200 OK  124ms  2.3KB    Body | Headers       │
│          │  ┌─────────────────────────────────────────┐  │
│          │  │  { "id": 1, "name": "..." }             │  │
│          │  └─────────────────────────────────────────┘  │
└──────────┴──────────────────────────────────────────────┘
```

## Goals / Non-Goals

**Goals:**
- Dark-only theme matching Insomnia's default dark palette.
- Three-pane layout: sidebar | (request / response stacked).
- Colored HTTP method badges.
- Flat IDE-style tabs, no Material elevation.
- Monospace fonts for all code-like fields.
- Compact desktop density.
- Unified look across Linux and Windows.

**Non-Goals:**
- Light theme support (dark only for now).
- Platform-specific native widgets (unified look).
- Resizable sidebar (can be added later).
- Custom window chrome / titlebar.
- Theme switching / multiple themes.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Theme approach | Custom `ThemeData` with explicit colors, no `ColorScheme.fromSeed` | Full control over every color. Insomnia's palette doesn't map cleanly to Material's seed system. |
| Layout structure | `Row` → sidebar (fixed 260px) + `Column` → request pane (flex) + divider + response pane (flex) | Matches Insomnia's three-pane model. Request and response are vertically stacked in the center column. |
| Sidebar | Custom `TreeView`-like widget using `ExpansionTile` and `ListTile` with dense styling | Replaces `NavigationRail`. Shows collections tree, environment dropdown, and history. |
| Method badge | Small `Container` with colored background, white text, 3px horizontal padding | Matches Insomnia's compact colored method labels. |
| Tabs | Custom tab widget or styled `TabBar` with `indicator: BoxDecoration(border: Border(bottom: ...))` | Flat bottom-border indicator instead of Material's default pill indicator. |
| Monospace font | System monospace (`monospace` font family in Flutter) | No need to bundle a font file. `FontFamily.monospace` maps to the OS monospace. |
| Borders | `Border.all(color: Color(0xFF3A3A3A), width: 0.5)` between panels | Subtle separation without elevation. |
| Density | `VisualDensity.compact` on all interactive widgets, 4-8px padding | Desktop-appropriate density. |
| Status tags | Small colored `Text` widgets: green for 2xx, orange for 3xx, red for 4xx/5xx | Matches Insomnia's response status display. |

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Custom theme may conflict with some Material widgets that expect seed colors. | Override specific widget themes (AppBar, ListTile, TabBar, etc.) explicitly. |
| No light mode may frustrate users who prefer it. | Acceptable for now — user explicitly requested dark-only. Can add later. |
| Custom tab widget may lose accessibility features of Material TabBar. | Use styled `TabBar` with custom `indicator` and `labelStyle` rather than building from scratch. |
| Monospace system font varies across platforms. | Acceptable — both Linux and Windows have adequate monospace fonts. |
| Layout restructure is a large diff. | Keep the same widget classes; change their structure and styling. Don't rewrite logic. |
