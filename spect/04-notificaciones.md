# 04 — Notificaciones

Framework: **UserNotifications** (notificaciones **locales**, sin servidor en el MVP).

## Permisos

- Solicitar con `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])`.
- Pedirlo en el onboarding, **después** de explicar el valor (no a quemarropa).
- Manejar el estado denegado: la app sigue funcionando, pero se muestra un aviso
  sutil de que las notificaciones están desactivadas y un link a Ajustes.

## Tipos de notificación (MVP)

| Tipo | Trigger | Ejemplo de copy |
|------|---------|-----------------|
| **Recordatorio diario** | Hora elegida por el usuario por goal (`UNCalendarNotificationTrigger`, repetitivo) | "👟 ¿Ya diste tus 10.000 pasos hoy? Vas por 6.200." |
| **Logro de meta** | Al detectar (vía observer) que un goal se completó | "🎉 ¡Meta cumplida! Llegaste a tus 30 min de ejercicio." |
| **Resumen / cierre de día** (opcional) | Fin del día (ej: 21:00) | "Hoy completaste 2 de 3 objetivos. ¡Mañana lo lográs!" |

> Post-MVP: notificaciones de racha (streak), "te falta poco" inteligente, semanal.

## Estrategia de programación

### Recordatorios diarios
- Por cada goal con `reminderEnabled == true` y `reminderTime`, programar un
  `UNCalendarNotificationTrigger` con `repeats: true` a esa hora.
- `identifier` determinístico: `"reminder-\(goal.id)"` → permite actualizar/cancelar.
- Al editar o borrar un goal, **reprogramar/cancelar** su notificación.
- Para personalizar el contenido con el progreso real, el cuerpo se actualiza cuando
  el observer recalcula (reprogramando la notificación pendiente con texto fresco).

### Logro de meta
- Disparada desde el flujo de `HKObserverQuery` → `ProgressCalculator` cuando
  `isCompleted` pasa de `false` a `true`.
- Evitar duplicados: marcar el goal/período como ya notificado (flag con la fecha
  del período) para no avisar dos veces el mismo día.
- `UNTimeIntervalNotificationTrigger` con intervalo mínimo (entrega inmediata).

## Protocolo de servicio

```swift
protocol NotificationScheduling {
    func requestAuthorization() async -> Bool
    func scheduleDailyReminder(for goal: Goal) async
    func cancelReminder(for goal: Goal) async
    func notifyGoalCompleted(_ goal: Goal) async
    func cancelAll() async
}
```

- Real: `NotificationService`.
- Test: `MockNotificationService` que registra llamadas.

## Buenas prácticas de UX

- **No hacer spam**: máximo 1 recordatorio por goal por día + logros puntuales.
- Tono **positivo y motivador**, nunca culpa ("vas genial", no "fallaste").
- Permitir activar/desactivar notificaciones **por objetivo** y globalmente.
- Respetar No molestar / horarios; no mandar recordatorios de madrugada.
- Localizar los textos (es / en).

## Consideraciones técnicas

- El límite del sistema es ~64 notificaciones locales pendientes por app → con pocos
  goals no es problema, pero programar de forma acotada.
- Manejar permisos en tiempo de ejecución (pueden cambiar desde Ajustes).
- Deep link: al tocar la notificación, abrir el **detalle del goal** correspondiente
  (usar `userInfo` con el `goalId` y manejar en `UNUserNotificationCenterDelegate`).
