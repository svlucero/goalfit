# 06 — Requisitos no funcionales

## Privacidad y seguridad

- Datos de salud **solo en el dispositivo** (MVP, sin backend ni analytics de salud).
- No loggear valores de salud ni enviarlos a terceros.
- Textos claros de uso en `Info.plist` (`NSHealthShareUsageDescription`).
- Cumplir las [HealthKit Review Guidelines](https://developer.apple.com/app-store/review/guidelines/#healthkit):
  no usar datos de salud para publicidad ni marketing.
- Incluir **política de privacidad** (requisito de App Store para apps de salud).

## Rendimiento

- Dashboard debe renderizar en < 1 s usando progreso cacheado, recalculando en background.
- Consultas a HealthKit acotadas por rango (no traer histórico completo).
- Trabajo de `HKObserverQuery` en background: breve, sin bloquear, llamar al
  `completionHandler` siempre.
- Animaciones a 60 fps; evitar recomputar en cada frame.

## Accesibilidad

- **Dynamic Type**: layouts que escalan con el tamaño de fuente.
- **VoiceOver**: labels descriptivos en tarjetas, anillos de progreso y botones
  (ej: "Pasos, 6.200 de 10.000, 62 por ciento").
- Contraste de color suficiente (WCAG AA); no depender solo del color para el estado.
- Soporte de **Dark Mode** y reducción de movimiento (`reduceMotion`).

## Internacionalización

- Strings localizables (mínimo es / en).
- Formateo de números, fechas y unidades con `Locale` / `MeasurementFormatter`
  (km vs millas, kg vs lb).

## Compatibilidad

- iOS 17.0+.
- iPhone (HealthKit no está en todos los iPad → manejar `isHealthDataAvailable`).
- Probar en dispositivo físico (el simulador tiene HealthKit limitado).

## Testing y calidad

| Nivel | Qué se prueba |
|-------|---------------|
| Unit | `ProgressCalculator` (todas las direcciones/períodos), ViewModels con mocks, `GoalRepository` (CRUD), formateo de unidades |
| Integración | Flujo Servicio↔Repositorio con store en memoria de SwiftData |
| UI | Crear objetivo, ver dashboard, editar/eliminar |
| Manual | HealthKit real en dispositivo, permisos denegados, estados vacíos, notificaciones |

- Mocks de `HealthDataProviding` y `NotificationScheduling` para tests deterministas.
- Objetivo de cobertura inicial razonable en la capa de dominio (lógica pura).
- CI opcional con GitHub Actions: `xcodebuild test` en cada PR.

## Observabilidad

- Logging con `OSLog` (categorías: health, notifications, persistence) **sin datos sensibles**.
- Manejo de errores con tipos `Error` específicos y mensajes amigables en UI.

## Distribución / App Store

- Capability HealthKit + descripción de uso → revisar guidelines de salud.
- Política de privacidad publicada (URL).
- "App Privacy" nutrition label declarando que los datos de salud no se recopilan/comparten.
- TestFlight para beta antes del release.
- Versionado semántico de la app + build numbers incrementales.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|--------|-----------|
| Permiso de lectura HealthKit no detectable | Estrategia de "intentar leer + estado vacío con guía" |
| Background delivery poco fiable / limitado | Recalcular también al abrir la app y con pull-to-refresh |
| Rechazo de App Store por uso de datos de salud | Seguir guidelines, copy claro, política de privacidad |
| Dependencia de iOS 17 reduce alcance | Aceptable para MVP; evaluar Core Data si se baja el target |
