# Plan: Deuda Técnica

Escaneado: 2026-07-04

---

## Deuda Técnica Identificada

### TD-1: Sidebar.dart 814 líneas
**Archivo:** `lib/ui/widgets/sidebar.dart`
**Problema:** Contiene ~10 métodos de dialog + build method complejo.
**Impacto:** Difícil de mantener, testear, y entender.
**Solución propuesta:** Extraer dialogs a `sidebar_dialogs.dart` usando una clase helper que reciba `WidgetRef` y `ColorSet` como parámetros.
**Esfuerzo:** Medio-Alto (requiere reestructurar las llamadas a ref)
**Riesgo:** Los dialogs usan `ref.read()` internamente, la extracción puede romper el state management.

### TD-2: DropdownButtonFormField → DropdownMenu migration
**Archivos:** auth_editor.dart (2), body_editor.dart (2), sidebar.dart (1)
**Problema:** `DropdownButtonFormField` abre centrado sobre el trigger.
**Impacto:** UX confusa en todos los dropdowns.
**Solución propuesta:** Migrar a `DropdownMenu` (Material 3) que soporta `alignment: AlignmentDirectional.topStart`.
**Esfuerzo:** Alto — cambia la API de cada dropdown (initialValue → initialSelection, items → dropdownMenuEntries).
**Riesgo:** Cambio de API puede requerir actualización de tests si existen.

### TD-3: Syntax theme no adapta a light mode
**Archivos:** `lib/ui/theme/app_theme.dart` (sootSyntaxTheme), `lib/ui/widgets/response_panel.dart`
**Problema:** `sootSyntaxTheme` usa colores oscuros (accent red, muted grey) que pueden no verse bien en fondo claro.
**Impacto:** Syntax highlighting ilegible o de bajo contraste en Soot Light.
**Solución propuesta:** Crear `sootLightSyntaxTheme` con colores más oscuros para fondo claro, o hacer el syntax theme completamente dinámico.
**Esfuerzo:** Medio — requiere generar paleta de syntax alternativa.
**Riesgo:** Bajo — es solo agregar un mapa de colores.

### TD-4: No hay tests unitarios para UI
**Archivos:** `test/` directory
**Problema:** Los tests existentes son para servicios, no para widgets.
**Impacto:** Los bugs de UI (como BUG-1 auth_editor) pasan desapercibidos.
**Solución propuesta:** Agregar tests de widget para componentes críticos (sidebar, request_editor, response_panel).
**Esfuerzo:** Alto — requiere setup de flutter_test con providers mock.
**Riesgo:** Bajo — tests no cambian comportamiento.

### TD-5: No hay error boundaries
**Archivo:** `lib/ui/app.dart`
**Problema:** `FlutterError.onError` no está configurado.
**Impacto:** Errores de widget crashean la app sin feedback al usuario.
**Solución propuesta:** Agregar `FlutterError.onError` handler que muestre un SnackBar o dialog con el error.
**Esfuerzo:** Bajo.
**Riesgo:** Bajo.

### TD-6: Window title no se actualiza
**Archivo:** `lib/ui/screens/main_screen.dart`
**Problema:** Window title siempre muestra "HTTP Client".
**Impacto:** Usuario no sabe qué request está viendo.
**Solución propuesta:** Actualizar window title con el nombre del request actual usando `window_manager`.
**Esfuerzo:** Bajo.
**Riesgo:** Bajo.

### TD-7: No hay persistencia de workspace path
**Archivo:** `lib/ui/screens/main_screen.dart`
**Problema:** `_loadWorkspace` carga de Documents en cada inicio.
**Impacto:** Si el usuario cambia de workspace, se pierde al reiniciar.
**Solución propuesta:** Guardar workspace path en SharedPreferences.
**Esfuerzo:** Bajo.
**Riesgo:** Bajo.

---

## Prioridad de Implementación

| TD | Esfuerzo | Impacto | Prioridad |
|---|---|---|---|
| TD-5: Error boundaries | Bajo | Alto | 1 |
| TD-6: Window title | Bajo | Medio | 2 |
| TD-7: Workspace persistence | Bajo | Medio | 3 |
| TD-3: Syntax light theme | Medio | Medio | 4 |
| TD-1: Sidebar refactor | Alto | Medio | 5 |
| TD-4: Widget tests | Alto | Alto | 6 |
| TD-2: Dropdown migration | Alto | Medio | 7 |

---

## Estimación de Esfuerzo Total

| TD | Horas estimadas |
|---|---|
| TD-1: Sidebar refactor | 4-6h |
| TD-2: Dropdown migration | 6-8h |
| TD-3: Syntax light theme | 2-3h |
| TD-4: Widget tests | 8-12h |
| TD-5: Error boundaries | 1h |
| TD-6: Window title | 1h |
| TD-7: Workspace persistence | 1h |
| **Total** | **23-33h** |
