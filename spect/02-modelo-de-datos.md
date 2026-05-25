# 02 — Modelo de datos

## Entidades de dominio

### `GoalType` (enum)

Describe qué métrica de HealthKit mide el objetivo y cómo se interpreta.

```swift
enum GoalType: String, Codable, CaseIterable {
    case steps              // pasos
    case distance           // distancia caminando/corriendo
    case activeEnergy       // calorías activas
    case exerciseMinutes    // minutos de ejercicio
    case bodyMass           // peso corporal (target)
}
```

Cada tipo conoce:
- El `HKQuantityType` / `HKSampleType` de HealthKit asociado.
- La unidad por defecto (`HKUnit`): pasos, km, kcal, min, kg.
- Si es **acumulativo** (suma del día/semana: pasos, distancia, calorías, minutos) o
  **discreto/target** (último valor vs meta: peso).

### `GoalPeriod` (enum)

```swift
enum GoalPeriod: String, Codable {
    case daily      // se evalúa por día
    case weekly     // se evalúa por semana
    case target     // meta única (ej: alcanzar un peso) sin reinicio
}
```

### `GoalDirection` (enum)

```swift
enum GoalDirection: String, Codable {
    case atLeast    // cumplir = alcanzar o superar (pasos, distancia...)
    case atMost     // cumplir = mantenerse por debajo
    case reach      // llegar a un valor objetivo (peso target)
}
```

### `Goal` (modelo persistido — SwiftData `@Model`)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | `UUID` | Identificador único |
| `title` | `String` | Nombre que ve el usuario (ej: "Caminar más") |
| `type` | `GoalType` | Métrica asociada |
| `period` | `GoalPeriod` | daily / weekly / target |
| `direction` | `GoalDirection` | atLeast / atMost / reach |
| `targetValue` | `Double` | Valor meta en la unidad del tipo |
| `startValue` | `Double?` | Valor de partida (para metas `reach`, ej: peso inicial) |
| `unit` | `String` | Unidad legible (pasos, km, kcal, min, kg) |
| `createdAt` | `Date` | Fecha de creación |
| `deadline` | `Date?` | Fecha límite opcional (para `target`) |
| `isActive` | `Bool` | Activo / archivado |
| `reminderEnabled` | `Bool` | Si manda recordatorio |
| `reminderTime` | `Date?` | Hora del recordatorio diario |

> Nota: en SwiftData los enums `Codable` se persisten como su `rawValue`.

### `GoalProgress` (calculado, no necesariamente persistido)

Resultado de `ProgressCalculator` para un goal en un período concreto.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `goalId` | `UUID` | Goal al que pertenece |
| `currentValue` | `Double` | Valor actual leído de HealthKit |
| `targetValue` | `Double` | Meta |
| `fraction` | `Double` | Progreso 0.0–1.0 (clamp) |
| `isCompleted` | `Bool` | Si se cumplió la meta |
| `periodStart` | `Date` | Inicio del período evaluado |
| `periodEnd` | `Date` | Fin del período evaluado |
| `lastUpdated` | `Date` | Cuándo se calculó |

### `HealthDataPoint` (DTO de lectura)

Representa un punto agregado leído de HealthKit (ej: pasos por día) para graficar.

| Campo | Tipo |
|-------|------|
| `date` | `Date` |
| `value` | `Double` |

## Cálculo de progreso

`ProgressCalculator` toma un `Goal` + las samples relevantes y produce `GoalProgress`:

- **Acumulativo** (`steps`, `distance`, `activeEnergy`, `exerciseMinutes`):
  `currentValue = suma de samples en el período`.
  - `fraction = min(currentValue / targetValue, 1.0)` para `atLeast`.
- **Target / reach** (`bodyMass`):
  `currentValue = última muestra`.
  - `fraction = (startValue - currentValue) / (startValue - targetValue)` con clamp,
    soportando subir o bajar de peso según dirección.
- `isCompleted`:
  - `atLeast`: `currentValue >= targetValue`.
  - `atMost`: `currentValue <= targetValue`.
  - `reach`: el usuario alcanzó el `targetValue` dentro de una tolerancia.

> Toda esta lógica es **pura y sin estado** → 100% testeable con unit tests.

## Persistencia

- `Goal` se guarda en **SwiftData** (contenedor en el `App`).
- `GoalProgress` puede **cachearse** (opcional) para mostrar el dashboard al instante
  mientras se recalcula en background. Fuente de verdad del progreso = HealthKit.
- Datos crudos de salud: **no se persisten**, se consultan on-demand.

## Diagrama de relaciones

```
GoalType ──describe──> Goal ──genera──> GoalProgress
                         │
                         └──(HealthKitService lee samples)──> [HealthDataPoint]
```
