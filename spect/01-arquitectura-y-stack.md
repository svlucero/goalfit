# 01 — Arquitectura y stack técnico

## Decisión de plataforma

**iOS nativo con Swift + SwiftUI.**

Justificación:
- HealthKit es una API exclusiva de iOS y su integración completa (lectura,
  `HKObserverQuery`, background delivery) es más robusta y estable de forma nativa.
- SwiftUI permite construir el dashboard y formularios rápido, con buen soporte de
  gráficos vía **Swift Charts**.
- Evitamos capas de puente (React Native / Flutter) que complican el acceso a
  HealthKit y a notificaciones en background.

### Requisitos de plataforma

- **Target mínimo:** iOS 17.0 (Swift Charts maduro, observación moderna con `@Observable`).
- **Lenguaje:** Swift 5.9+.
- **UI:** SwiftUI (UIKit solo si algo puntual lo requiere).
- **IDE / build:** Xcode 15+.

## Arquitectura general

Patrón **MVVM** con una capa de servicios desacoplada por protocolos (para testear
sin tocar HealthKit real).

```
┌─────────────────────────────────────────────┐
│                    Views (SwiftUI)            │
│   Dashboard · GoalDetail · GoalForm · Onboarding │
└───────────────┬───────────────────────────────┘
                │ binding (@Observable ViewModels)
┌───────────────▼───────────────────────────────┐
│                  ViewModels                    │
│  DashboardVM · GoalDetailVM · GoalFormVM       │
└───────────────┬───────────────────────────────┘
                │ usa (protocolos)
┌───────────────▼───────────────────────────────┐
│                   Services                     │
│  HealthKitService · NotificationService        │
│  GoalRepository · ProgressCalculator           │
└───────────────┬───────────────────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│        Frameworks de sistema / persistencia    │
│   HealthKit · UserNotifications · SwiftData     │
└─────────────────────────────────────────────────┘
```

## Capas y responsabilidades

### Models (dominio)
- `Goal`, `GoalType`, `GoalProgress`, `HealthSample`. Ver [`02-modelo-de-datos.md`](./02-modelo-de-datos.md).

### Services
| Servicio | Responsabilidad | Protocolo |
|----------|-----------------|-----------|
| `HealthKitService` | Pedir permisos, leer métricas, observar cambios | `HealthDataProviding` |
| `NotificationService` | Permisos, programar/cancelar notificaciones locales | `NotificationScheduling` |
| `GoalRepository` | CRUD de objetivos sobre SwiftData | `GoalStoring` |
| `ProgressCalculator` | Calcular progreso de un goal a partir de samples | (puro, sin estado) |

> Cada servicio se expone vía un **protocolo** para inyectar mocks en tests y previews.

### ViewModels
- Orquestan servicios, exponen estado a la vista (`@Observable`).
- No conocen detalles de HealthKit/SwiftData, solo los protocolos.

### Views
- SwiftUI puro, declarativas, sin lógica de negocio.

## Persistencia

**SwiftData** (iOS 17+) para almacenar los objetivos (`Goal`) y, opcionalmente,
snapshots de progreso cacheados.

- Los **datos de salud crudos NO se persisten**: siempre se leen de HealthKit (fuente
  de verdad) y se cachea solo el progreso calculado para mostrar rápido.
- Alternativa si se necesita soporte < iOS 17: Core Data. Se opta por SwiftData por
  simplicidad y por el target iOS 17.

## Concurrencia

- **Swift Concurrency** (`async/await`, actores) para lecturas de HealthKit.
- `HealthKitService` puede ser un `actor` para serializar el acceso.
- Las queries de observación (`HKObserverQuery`) corren en background y disparan
  recálculo de progreso + actualización de notificaciones.

## Estructura de carpetas propuesta (Xcode)

```
GoalFit/
├── App/
│   ├── GoalFitApp.swift          # @main, setup de contenedor SwiftData
│   └── AppContainer.swift        # inyección de dependencias
├── Models/
│   ├── Goal.swift
│   ├── GoalType.swift
│   └── GoalProgress.swift
├── Services/
│   ├── Health/
│   │   ├── HealthDataProviding.swift
│   │   └── HealthKitService.swift
│   ├── Notifications/
│   │   ├── NotificationScheduling.swift
│   │   └── NotificationService.swift
│   ├── Persistence/
│   │   ├── GoalStoring.swift
│   │   └── GoalRepository.swift
│   └── Progress/
│       └── ProgressCalculator.swift
├── Features/
│   ├── Onboarding/
│   ├── Dashboard/
│   ├── GoalForm/
│   └── GoalDetail/
├── DesignSystem/                 # colores, tipografías, componentes reutilizables
└── Resources/                    # assets, localizables, Info.plist
GoalFitTests/                     # unit tests con mocks
GoalFitUITests/                   # UI tests críticos
```

## Inyección de dependencias

DI simple y manual vía un `AppContainer` que crea las instancias de servicios y las
pasa a los ViewModels (a través del `Environment` de SwiftUI o por init). Sin
librerías externas para no agregar complejidad.

## Dependencias externas

**Ninguna obligatoria en el MVP.** Todo se resuelve con frameworks de Apple
(HealthKit, UserNotifications, SwiftData, Swift Charts). Esto minimiza riesgo,
tamaño del binario y mantenimiento.

Si en el futuro hace falta sync en la nube → **CloudKit** (también de Apple).

## Capabilities / entitlements requeridos

- **HealthKit** capability.
- **Background Modes** (opcional, para background delivery de HealthKit).
- **Push Notifications**: NO se necesitan remotas en el MVP (solo locales, que no
  requieren entitlement especial).

## Estrategia de testing

- **Unit tests**: `ProgressCalculator` (lógica pura), ViewModels (con mocks de
  servicios), `GoalRepository`.
- **Mocks**: implementaciones fake de `HealthDataProviding` y `NotificationScheduling`.
- **UI tests**: flujo de crear objetivo y ver dashboard.
- Ver [`06-requisitos-no-funcionales.md`](./06-requisitos-no-funcionales.md).
