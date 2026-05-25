# 03 — Integración con HealthKit

## Objetivo

Leer de la app de Salud los datos necesarios para calcular el progreso de cada
objetivo, de forma **solo lectura** (read-only) en el MVP, respetando permisos y
privacidad.

## Setup del proyecto

1. Activar la capability **HealthKit** en el target (Signing & Capabilities).
2. Agregar las claves de uso en `Info.plist`:
   - `NSHealthShareUsageDescription` → texto que explica por qué leemos datos de salud.
   - (`NSHealthUpdateUsageDescription` solo si en el futuro escribimos datos).
3. Verificar disponibilidad: `HKHealthStore.isHealthDataAvailable()` (false en iPad/algunos devices).

## Tipos de datos (HKObjectType) requeridos

| GoalType | HealthKit type | Unidad |
|----------|----------------|--------|
| `steps` | `HKQuantityType(.stepCount)` | `count` |
| `distance` | `HKQuantityType(.distanceWalkingRunning)` | `meter` → mostrar en km |
| `activeEnergy` | `HKQuantityType(.activeEnergyBurned)` | `kilocalorie` |
| `exerciseMinutes` | `HKQuantityType(.appleExerciseTime)` | `minute` |
| `bodyMass` | `HKQuantityType(.bodyMass)` | `gramUnit(with: .kilo)` |

> Se solicita permiso solo para los tipos que el usuario realmente usa. Estrategia
> MVP: pedir el set completo en el onboarding para simplificar.

## Permisos

- `HKHealthStore.requestAuthorization(toShare: [], read: readTypes)`.
- **Importante:** por privacidad, iOS NO informa si el permiso de *lectura* fue
  denegado. `authorizationStatus(for:)` solo es fiable para *escritura*.
  - ⇒ La estrategia correcta es **intentar leer**: si no hay datos, mostrar un estado
    vacío con ayuda ("Activá el acceso en Ajustes > Salud"), sin asumir denegación.
- Manejar el caso de "datos no disponibles" (device sin Health).

## Lectura de datos

### Consulta acumulativa (pasos, distancia, calorías, minutos)

Usar `HKStatisticsQuery` o `HKStatisticsCollectionQuery`:
- Para el progreso del período actual: `HKStatisticsQuery` con `.cumulativeSum`
  acotado al intervalo (día o semana).
- Para el histórico (gráfico de 7 días): `HKStatisticsCollectionQuery` con
  `anchorDate` a medianoche e `intervalComponents = DateComponents(day: 1)`.

### Consulta de target (peso)

- `HKSampleQuery` ordenado por fecha descendente, `limit: 1` → último valor.
- Para histórico: muestras dentro del rango, ordenadas.

### Predicados de tiempo

- Día actual: desde `startOfDay` hasta ahora (`HKQuery.predicateForSamples`).
- Semana actual: desde el inicio de la semana según `Calendar.current`.

## Observación de cambios (mantener progreso al día)

- `HKObserverQuery` por cada tipo activo → se dispara cuando hay datos nuevos.
- Habilitar **background delivery**: `enableBackgroundDelivery(for:frequency:)`
  (requiere Background Modes). Frecuencia `.immediate` o `.hourly`.
- Al recibir un cambio:
  1. Recalcular el progreso de los goals afectados.
  2. Actualizar la UI / cache.
  3. Reevaluar notificaciones (ej: disparar "¡meta cumplida!").
  4. Llamar al `completionHandler` del observer.

> El observer en background tiene tiempo limitado; mantener el trabajo breve.

## Protocolo de servicio

```swift
protocol HealthDataProviding {
    func isHealthDataAvailable() -> Bool
    func requestAuthorization(for types: [GoalType]) async throws
    func currentValue(for goal: Goal) async throws -> Double
    func dailySeries(for goal: Goal, days: Int) async throws -> [HealthDataPoint]
    func startObserving(_ types: [GoalType], onChange: @escaping () -> Void)
}
```

Implementación real: `HealthKitService` (puede ser `actor`).
Implementación de test: `MockHealthService` con datos sintéticos.

## Edge cases a contemplar

- HealthKit no disponible en el dispositivo → ocultar/avisar.
- Sin datos para el rango (usuario sin Apple Watch / sin actividad) → estado vacío.
- Permiso de lectura denegado (no detectable directamente) → guía a Ajustes.
- Cambios de unidad / localización (km vs millas) → usar `Locale` para mostrar.
- Zonas horarias y cambios de día (usar `Calendar.current` consistentemente).
- Datos de múltiples fuentes (iPhone + Watch) → HealthKit ya deduplica con `statistics`.
- Performance: limitar rangos de consulta y cachear resultados.

## Privacidad

- Datos de salud **nunca salen del dispositivo** en el MVP.
- No logging de valores de salud.
- Cumplir con las [HealthKit Review Guidelines](https://developer.apple.com/app-store/review/guidelines/#healthkit) de App Store.
