# Plan: Bugs y Errores Introducidos

Escaneado: 2026-07-04

---

## Bugs Confirmados

### BUG-1: auth_editor.dart no es ConsumerStatefulWidget
**Archivo:** `lib/ui/widgets/auth_editor.dart:6`
**Problema:** `AuthEditor extends StatefulWidget` en vez de `ConsumerStatefulWidget`
**Impacto:** No puede acceder a `ref` para usar `colorSetProvider`. Los colores no se actualizan al cambiar de tema.
**Fix:** Convertir a `ConsumerStatefulWidget`, agregar `final colors = ref.watch(colorSetProvider);` en build.
**Severidad:** Alta — el auth editor no cambia de tema.

### BUG-2: main_screen.dart usa AppColors.surface
**Archivo:** `lib/ui/screens/main_screen.dart:80`
**Problema:** `color: AppColors.surface` en vez de `colors.surface`
**Impacto:** El sidebar background no se actualiza al cambiar de tema.
**Fix:** Reemplazar con `colors.surface` (ya tiene `final colors = ref.watch(colorSetProvider);` en build).
**Severidad:** Media — sidebar background no cambia.

### BUG-3: response_panel diff usa ColorSet.dark
**Archivo:** `lib/ui/widgets/response_panel.dart:233`
**Problema:** `_buildDiffText(diffs, ColorSet.dark)` — hardcodea el dark set en vez de usar `colors`.
**Impacto:** Los colores de diff no se adaptan al tema activo (light/orange).
**Fix:** Cambiar a `_buildDiffText(diffs, colors)`.
**Severidad:** Baja — solo afecta diff viewer en temas no-dark.

### BUG-4: sidebar historySearch provider existe pero no se usa
**Archivo:** `lib/providers/app_state.dart:186`
**Problema:** `historySearchProvider` fue agregado pero el search field fue revertido.
**Impacto:** Código muerto que confunde.
**Fix:** Eliminar `historySearchProvider` de app_state.dart.
**Severidad:** Baja — código muerto.

### BUG-5: _VirtualBody recibe colors pero no adapta syntax theme
**Archivo:** `lib/ui/widgets/response_panel.dart:332`
**Problema:** `theme: sootSyntaxTheme(widget.colors)` — usa los colores del tema activo, pero el syntax theme puede no verse bien en light mode (colores muy oscuros).
**Impacto:** Syntax highlighting puede ser ilegible en light mode.
**Fix:** Verificar contraste en light mode o crear variante light del syntax theme.
**Severidad:** Media — legibilidad en light mode.

---

## Inconsistencias UI

### INC-1: DropdownButtonFormField abre centrado
**Archivos:** auth_editor.dart, body_editor.dart, sidebar.dart (5 dropdowns)
**Problema:** Los dropdowns abren centrados sobre el trigger, cubriendo contenido.
**Impacto:** UX confusa — el usuario no sabe si el dropdown abrió arriba o abajo.
**Fix:** Migrar a DropdownMenu (Material 3) o aceptar como limitación de Flutter.
**Severidad:** Media.

### INC-2: ClickCursor no está en todos los interactive elements
**Archivos:** body_editor.dart (IconButton close), sidebar.dart (visibility toggle)
**Problema:** Algunos IconButtons no tienen ClickCursor.
**Impacto:** Cursor no cambia a pointer en desktop.
**Fix:** Agregar ClickCursor wrappers.
**Severidad:** Baja.

### INC-3: Settings tab tiene opciones no funcionales
**Archivo:** `lib/ui/widgets/request_editor.dart:314-328`
**Problema:** "Follow redirects", "Verify SSL", "Send cookies", "Request timeout", "Max response size" son solo display, no funcionales.
**Impacto:** Usuario cree que puede configurar esto pero no puede.
**Fix:** O implementar las opciones o agregar "Coming soon" explícito.
**Severidad:** Baja.

---

## Inconsistencias de Estado/Providers

### INC-4: ThemeVariantNotifier state no se persiste correctamente
**Archivo:** `lib/providers/app_state.dart:165-182`
**Problema:** El constructor carga de SharedPreferences pero `state = variant` puede no persistir si la app se cierra antes del await.
**Impacto:** Raro pero posible — theme selection se pierde.
**Fix:** Usar `WidgetsBinding.instance.addPostFrameCallback` para cargar después del primer frame.
**Severidad:** Baja.

### INC-5: collectionsProvider no tiene manejo de error explícito
**Archivo:** `lib/providers/app_state.dart:47-51`
**Problema:** `AsyncValue<List<RequestCollection>>` pero no hay `.error` handling visible en el sidebar.
**Impacto:** Si falla la carga, el usuario ve un spinner infinito.
**Fix:** Agregar error handling explícito en el sidebar.
**Severidad:** Baja.

---

## Prioridad de Fix

| Bug | Severidad | Esfuerzo |
|---|---|---|
| BUG-1: auth_editor StatefulWidget | Alta | Bajo |
| BUG-2: main_screen AppColors.surface | Media | Bajo |
| BUG-3: diff ColorSet.dark hardcodeado | Baja | Bajo |
| BUG-4: historySearchProvider unused | Baja | Bajo |
| BUG-5: syntax theme light mode | Media | Medio |
| INC-1: Dropdown centrado | Media | Alto |
| INC-2: ClickCursor missing | Baja | Bajo |
| INC-3: Settings no funcionales | Baja | Bajo |
| INC-4: Theme persistence edge case | Baja | Bajo |
| INC-5: Error handling | Baja | Medio |
