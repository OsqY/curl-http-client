# Plan de Acción: Deuda Técnica Pendiente

Fecha: 2026-07-04

---

## 1. DropdownButtonFormField → DropdownMenu Migration

**Objetivo:** Los dropdowns abren centrados sobre el trigger. Migrar a DropdownMenu (Material 3) que soporta `alignment: AlignmentDirectional.topStart` para abrir hacia abajo.

**Archivos a modificar:**
- `lib/ui/widgets/auth_editor.dart` (2 dropdowns: auth type, ApiKey location)
- `lib/ui/widgets/body_editor.dart` (2 dropdowns: BodyMode, RawContentType)
- `lib/ui/widgets/sidebar.dart` (1 dropdown: Environment selector)

**API changes:**
```dart
// Antes (DropdownButtonFormField)
DropdownButtonFormField<BodyMode>(
  value: body.mode,
  items: [...],
  onChanged: (m) { ... },
)

// Después (DropdownMenu)
DropdownMenu<BodyMode>(
  initialSelection: body.mode,
  dropdownMenuEntries: [...],
  onSelected: (m) { ... },
  alignment: AlignmentDirectional.topStart,
)
```

**Riesgo:** Medio — cambia la API de cada dropdown. Los widgets necesitan importar `material.dart` (ya lo tienen).

---

## 2. Syntax Theme Light Mode

**Objetivo:** Asegurar que los colores del syntax theme sean legibles en fondos claros (Soot Light: bg #FAFAFA).

**Colores actuales:**
- mutedGrey (#5D636F) para comentarios — podría ser bajo contraste en light bg
- textPlaceholder (#515154) para disabled — bajo contraste en light bg

**Solución:** Crear `sootLightSyntaxTheme` con colores más oscuros para comentarios y placeholders.

**Archivos a modificar:**
- `lib/ui/theme/app_theme.dart` — agregar variante light del syntax theme
- `lib/ui/widgets/response_panel.dart` — usar variante light cuando el tema es light

---

## 3. Widget Tests Básicos

**Objetivo:** Agregar tests mínimos para componentes críticos.

**Tests a agregar:**
- `test/widgets/method_badge_test.dart` — renderiza colores correctos por método
- `test/widgets/status_tag_test.dart` — renderiza colores correctos por status code
- `test/widgets/click_cursor_test.dart` — renderiza MouseRegion

**Framework:** `flutter_test` con `testWidgets()`

---

## Ejecución

| Paso | Descripción | Archivos |
|---|---|---|
| 1 | Migrar DropdownButtonFormField a DropdownMenu | auth_editor, body_editor, sidebar |
| 2 | Crear sootLightSyntaxTheme | app_theme.dart |
| 3 | Actualizar response_panel para usar variante light | response_panel.dart |
| 4 | Agregar tests básicos | test/widgets/*.dart |
| 5 | Verificar analyze + format + tests | — |
