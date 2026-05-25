# 07 — Backlog por pasos

Roadmap incremental de GoalFit. Cada **paso** es un incremento funcional pequeño que
se puede desarrollar, revisar y mergear de forma independiente. Están ordenados por
dependencia: idealmente se hacen de arriba hacia abajo.

Convención sugerida para issues de GitHub: usar el título del paso como título del
issue, el bloque como descripción, y la columna *Done cuando* como criterios de aceptación.

---

## 🏁 Milestone 0 — Fundaciones del proyecto

### Paso 0.1 — Setup del proyecto Xcode
- Crear proyecto iOS (SwiftUI, iOS 17+), bundle id, organización.
- Estructura de carpetas según [`01-arquitectura-y-stack.md`](./01-arquitectura-y-stack.md).
- Configurar Git, `.gitignore` de Xcode, esquema de build.
- **Done cuando:** el proyecto compila y corre una pantalla "Hello GoalFit".

### Paso 0.2 — Sistema de diseño base
- Definir paleta de color (acento + semánticos), tipografía, espaciados.
- Componentes base: `ProgressRing`, `GoalCard` (placeholder), `EmptyState`, botón primario.
- Soporte Dark Mode.
- **Done cuando:** existe una galería/preview de componentes reutilizables.

### Paso 0.3 — Modelos de dominio + persistencia
- Implementar `GoalType`, `GoalPeriod`, `GoalDirection`, `Goal` (`@Model` SwiftData),
  `GoalProgress`, `HealthDataPoint`.
- Configurar contenedor SwiftData en el `App`.
- `GoalStoring` + `GoalRepository` (CRUD) con store en memoria para tests.
- **Done cuando:** se puede crear/leer/borrar un `Goal` en memoria con un test que pasa.

---

## 🏁 Milestone 1 — CRUD de objetivos (sin HealthKit todavía)

### Paso 1.1 — Dashboard con lista de objetivos (datos mock)
- `DashboardVM` + pantalla Dashboard que lista goals desde el repositorio.
- Tarjetas con progreso **simulado** (fraction fija) por ahora.
- Estados: vacío, con objetivos.
- **Done cuando:** se ven las tarjetas de goals persistidos.

### Paso 1.2 — Crear objetivo (GoalForm)
- Formulario de creación con selector de tipo, meta, período, recordatorio (toggle).
- Validaciones. Guardar persiste en SwiftData y refresca el dashboard.
- **Done cuando:** se puede crear un goal y aparece en el dashboard.

### Paso 1.3 — Editar y eliminar objetivo
- Reusar GoalForm en modo edición; acción eliminar con confirmación.
- **Done cuando:** se puede editar y borrar un goal existente.

---

## 🏁 Milestone 2 — Integración con HealthKit

### Paso 2.1 — Servicio HealthKit + permisos
- Capability HealthKit + claves en `Info.plist`.
- `HealthDataProviding` + `HealthKitService` con `requestAuthorization`.
- `isHealthDataAvailable` y manejo de no disponibilidad.
- **Done cuando:** la app pide permiso de Salud y maneja aceptar/denegar.

### Paso 2.2 — Lectura de progreso actual
- Implementar `currentValue(for:)` con `HKStatisticsQuery` (acumulativos) y
  `HKSampleQuery` (peso).
- `ProgressCalculator` (lógica pura) + unit tests de todas las direcciones/períodos.
- **Done cuando:** el dashboard muestra progreso **real** leído de HealthKit.

### Paso 2.3 — Estados de permiso/datos en la UI
- Banner "activá Salud en Ajustes", estado vacío sin datos, loading skeletons,
  pull-to-refresh.
- **Done cuando:** todos los estados de HealthKit se manejan con buen UX.

### Paso 2.4 — Detalle de objetivo con histórico (7 días)
- `dailySeries(for:days:)` con `HKStatisticsCollectionQuery`.
- Pantalla GoalDetail con anillo grande + gráfico (Swift Charts).
- **Done cuando:** se ve el detalle con gráfico de los últimos 7 días.

### Paso 2.5 — Observación de cambios (background)
- `HKObserverQuery` + `enableBackgroundDelivery` (Background Modes).
- Recalcular progreso al recibir cambios y al abrir la app.
- **Done cuando:** el progreso se actualiza solo cuando hay datos nuevos en Salud.

---

## 🏁 Milestone 3 — Notificaciones

### Paso 3.1 — Servicio de notificaciones + permisos
- `NotificationScheduling` + `NotificationService`, `requestAuthorization`.
- Manejo de permiso denegado en UI + link a Ajustes.
- **Done cuando:** la app pide permiso de notificaciones y refleja el estado.

### Paso 3.2 — Recordatorios diarios por objetivo
- Programar `UNCalendarNotificationTrigger` por goal con `reminderTime`.
- Reprogramar/cancelar al editar/eliminar el goal.
- Deep link al detalle del goal al tocar la notificación.
- **Done cuando:** llega un recordatorio a la hora elegida y abre el goal correcto.

### Paso 3.3 — Notificación de meta cumplida
- Disparar desde el flujo del observer cuando `isCompleted` pasa a true.
- Evitar duplicados por período.
- **Done cuando:** al cumplir una meta llega una notificación de logro (una sola vez).

---

## 🏁 Milestone 4 — Onboarding y ajustes

### Paso 4.1 — Onboarding
- Flujo de bienvenida + permisos (Salud y Notificaciones) + crear primer objetivo.
- Flag `hasCompletedOnboarding`.
- **Done cuando:** la primera vez se ve el onboarding y luego no se repite.

### Paso 4.2 — Settings
- Estado de permisos, switch global de notificaciones, acerca de, privacidad.
- **Done cuando:** se pueden ver/gestionar permisos y preferencias.

---

## 🏁 Milestone 5 — Pulido y release

### Paso 5.1 — Accesibilidad e i18n
- VoiceOver, Dynamic Type, contraste; localización es/en; formato de unidades.
- **Done cuando:** la app pasa una pasada de accesibilidad y está localizada es/en.

### Paso 5.2 — Testing y CI
- Cobertura de dominio (ProgressCalculator, ViewModels, Repository) + UI tests clave.
- GitHub Actions con `xcodebuild test` en PRs.
- **Done cuando:** CI corre tests verdes en cada PR.

### Paso 5.3 — Preparación App Store / TestFlight
- Íconos, screenshots, política de privacidad, App Privacy labels.
- Build de TestFlight para beta.
- **Done cuando:** hay una build en TestFlight lista para testers.

---

## 📊 Resumen de milestones

| Milestone | Foco | Entregable |
|-----------|------|------------|
| M0 | Fundaciones | Proyecto, diseño base, modelos + persistencia |
| M1 | CRUD objetivos | Crear/editar/borrar goals (mock progreso) |
| M2 | HealthKit | Progreso real + histórico + observación |
| M3 | Notificaciones | Recordatorios + logros |
| M4 | Onboarding/Settings | Primera experiencia + ajustes |
| M5 | Pulido/Release | A11y, i18n, tests, TestFlight |

**MVP = M0 + M1 + M2 + M3 + M4.** M5 es el camino al release público.

## 🔜 Post-MVP (no priorizado)

- Sync iCloud/CloudKit, widgets, app watchOS, rachas/gamificación, más tipos de
  objetivo (sueño, hidratación, workouts/semana), estadísticas avanzadas, social.
