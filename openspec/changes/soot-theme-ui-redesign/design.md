## Context

The app currently uses an Insomnia-style dark theme (from the insomnia-style-ui-redesign change). The user wants a complete reskin to the **Soot** aesthetic — a monochrome, dot-matrix-inspired theme influenced by Nothing Technology's design language, already implemented as a Zed editor extension at `~/Desktop/utils/nothing-theme/`.

Core philosophy: *"Subtract don't add"* — minimal color, structural borders as ornament, sparse signal accents. This is the opposite of the rainbow Insomnia palette.

## Soot Color Palette (from Zed extension `themes/soot.json`)

### Base Surfaces

| Token | Hex | Usage |
|---|---|---|
| `bg` | `#0C0C0E` | Root background, status bar, title bar |
| `surface` | `#161618` | Panels, sidebar, elevated surfaces, inputs |
| `elevated` | `#1C1C20` | Active tabs, elevated sections, dialogs |
| `hover` | `#202023` | Hover state for interactive elements |
| `active` | `#2A2A2E` | Active/pressed state, selected rows |

### Text

| Token | Hex | Usage |
|---|---|---|
| `text` | `#E9E9EB` | Primary body text |
| `text-muted` | `#8A8A8E` | Secondary labels, hints |
| `text-placeholder` | `#515154` | Placeholder text in inputs |
| `text-disabled` | `#515154` | Disabled text |

### Borders

| Token | Hex | Usage |
|---|---|---|
| `border` | `#3A3A3D` | Panel dividers, input borders |
| `border-variant` | `#232327` | Subtle internal borders |
| `border-focused` | `#E10F1C` | Focused input border (signal accent) |
| `border-selected` | `#6C0D14` | Selected item border |

### Accents

| Token | Hex | Usage |
|---|---|---|
| `accent` | `#E10F1C` | Primary signal: focused borders, keywords, errors, active indicators |
| `amber` | `#D9A441` | Constants, numbers, booleans |
| `green` | `#8AB36C` | Strings, success indicators |
| `steel-blue` | `#7FA6B8` | Types, enums, operators, tags |
| `muted-grey` | `#5D636F` | Comments, escape sequences |

### Scrollbar

| Token | Hex | Usage |
|---|---|---|
| `scrollbar-thumb` | `#E9E9EB2E` | Scrollbar thumb (translucent) |
| `scrollbar-hover` | `#4B4B4D` | Scrollbar thumb hover |

### Status Colors (HTTP)

| Range | Color | Hex |
|---|---|---|
| 2xx Success | green | `#8AB36C` |
| 3xx Redirect | steel-blue | `#7FA6B8` |
| 4xx Client Error | amber | `#D9A441` |
| 5xx Server Error | accent | `#E10F1C` |

### Method Badge Colors

Muted, monochrome-dominant. The method badge uses the surface color as background and the accent color only for the text of the active/current method. All methods get the same muted treatment rather than rainbow colors.

| Method | Text Color | Background |
|---|---|---|
| GET | `#8AB36C` (green) | `#8AB36C1A` (10% alpha) |
| POST | `#7FA6B8` (steel-blue) | `#7FA6B81A` |
| PUT | `#D9A441` (amber) | `#D9A4411A` |
| PATCH | `#AEBBCB` (light steel) | `#AEBBCB1A` |
| DELETE | `#E10F1C` (accent) | `#E10F1C1A` |
| HEAD | `#8A8A8E` (muted) | `#8A8A8E1A` |
| OPTIONS | `#8A8A8E` (muted) | `#8A8A8E1A` |

## Soot Syntax Theme (for response panel)

| Token | Color | Example |
|---|---|---|
| keyword / attribute / tag / title | `#E10F1C` (red) | `function`, `return`, `<div>` |
| constant / number / boolean | `#D9A441` (amber) | `42`, `true`, `null` |
| string / literal | `#8AB36C` (muted green) | `"hello"` |
| type / enum / operator | `#7FA6B8` (steel blue) | `String`, `GET` |
| function / constructor / variant | `#AEBBCB` (light steel) | `myFunc()`, `new Map` |
| comment / doc | `#5D636F` (muted grey) | `// TODO` |
| property | `#C9B9A6` (warm tan) | `object.key` |
| punctuation | `#8A8E96` (grey) | `{`, `,`, `;` |
| variable | `#E9E9EB` (white) | `x` |
| diff plus | `#8AB36C` | added lines |
| diff minus | `#E10F1C` | removed lines |

## Goals / Non-Goals

**Goals:**
- Replace Insomnia palette with Soot palette across all UI surfaces.
- Tame method badges from rainbow to monochrome + subtle accent.
- Replace vs2015 syntax highlighting with monochrome-dominant Soot syntax.
- Apply Soot's border/scrollbar/hover/selection system.
- Keep existing layout, widget structure, and all functionality intact.
- Achieve "subtract don't add" visual feel — less visual noise, more breathing room.

**Non-Goals:**
- Layout changes or restructure (sidebar position, pane ratios, tab order).
- New widgets or features (this is a pure reskin).
- Light theme support (dark-only, matching Soot Glyph variant).
- Custom window chrome, titlebar, or platform chrome.
- Font changes (uses system monospace; font family changes require user's `settings.json` equivalent).
- Theme switching (single theme for now).

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Base reference | Zed's `themes/soot.json` "Soot Glyph" variant | Already implements the Nothing-inspired monochrome palette for a developer tool context. |
| Palette source | Zed extension JSON, not brand hexes | The Soot palette is already tuned for code/UI readability; using it directly avoids reinventing. |
| Method badge approach | Muted monochrome with method-specific subtle color | Less visual competition than rainbow; each method still distinguishable by hue at low saturation. |
| Syntax theme | Custom SootSyntaxTheme using flutter_highlight's `HighlightView` with a custom theme map | vs2015 is high-contrast rainbow; Soot needs a monochrome-dominant replacement. |
| Status tag colors | Same as HTTP ranges above, consistent with Insomnia behavior but using Soot hues | Users need quick status identification; using Soot accent tokens keeps consistency. |
| Send button | No bright green; use accent red as subtle fill on hover | Soot doesn't do bright green CTAs; red accent is the signal. |
| Dialog backgrounds | Use elevated surface `#1C1C20` | Consistent with panel hierarchy. |
| Checkboxes in key-value | Use accent red for checked state | Only active color in the UI; draws attention to enabled vs disabled params. |

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Users accustomed to Insomnia rainbow colors may find monochrome harder to parse initially. | Method badges still use distinct muted hues per method, preserving recognizability. Signal accent (red) draws attention to critical items. |
| Red accent for Send button may feel like "danger" rather than "action" to some users. | Use accent as hover/border rather than full background; keep Send button as text + subtle border. Use green (#8AB36C) only for success states. |
| Low contrast between some surfaces (#0C0C0E bg vs #161618 surface) may be hard to read in bright environments. | This is a dark theme for a desktop developer tool; assume moderately controlled lighting. The Zed Soot theme already validated this contrast. |
| Custom syntax theme in flutter_highlight may not cover all token types. | Define all tokens that the vs2015 theme defined; fall back gracefully. |
| The diff viewer in response panel uses hardcoded green/red backgrounds for diff insert/delete — need Soot colors. | Update the `_buildDiffText` method to use Soot's green (#8AB36C) and red (#E10F1C) with appropriate alpha backgrounds. |

## Reference Layout (unchanged)

```
┌──────────┬──────────────────────────────────────────────┐
│          │  [GET] https://api.example.com/users  [Send]  │
│ Sidebar  │  Params | Headers | Auth | Body | Scripts     │
│ 260px    │  ┌─────────────────────────────────────────┐  │
│  ~bg     │  │  key          value                     │  │
│          │  │  ...                                     │  │
│          │  └─────────────────────────────────────────┘  │
│  Tree    │ ──────────── 1px border ────────────────────── │
│  Envs    │  200 OK  124ms  2.3KB    Body | Headers       │
│  History │  ┌─────────────────────────────────────────┐  │
│          │  │  { "id": 1, "name": "..." }             │  │
│          │  └─────────────────────────────────────────┘  │
└──────────┴──────────────────────────────────────────────┘
```
