# 05 — Dashboard y UX

## Mapa de pantallas

```
Onboarding (primera vez)
   └─> Dashboard (home)
         ├─> GoalForm (crear / editar objetivo)
         ├─> GoalDetail (progreso + histórico)
         └─> Settings (permisos, notificaciones, sobre)
```

## 1. Onboarding (solo primera vez)

Objetivo: explicar el valor y obtener permisos.

- **Pantalla 1 — Bienvenida**: qué hace GoalFit (1 frase + ilustración).
- **Pantalla 2 — Salud**: explicar por qué necesitamos HealthKit → botón que dispara
  el prompt de autorización de HealthKit.
- **Pantalla 3 — Notificaciones**: explicar recordatorios → botón que dispara el
  prompt de notificaciones.
- **Pantalla 4 — Primer objetivo**: CTA para crear el primer goal (lleva a `GoalForm`)
  o "saltar".
- Se marca `hasCompletedOnboarding` para no repetir.

## 2. Dashboard (home)

La pantalla principal. Muestra todos los objetivos activos y su progreso de un vistazo.

**Contenido:**
- Header con saludo + fecha + resumen ("2 de 3 objetivos al día").
- Lista/grid de **tarjetas de objetivo**, cada una con:
  - Ícono del tipo + título.
  - **Anillo o barra de progreso** (Swift Charts / shape) con `fraction`.
  - Valor actual / meta (ej: "6.200 / 10.000 pasos").
  - Estado: en progreso ✅ completado / ⏳ pendiente.
- Botón flotante **"+"** para crear objetivo nuevo.
- Pull-to-refresh para forzar recálculo desde HealthKit.

**Estados:**
- **Vacío** (sin objetivos): ilustración + CTA "Creá tu primer objetivo".
- **Sin permiso de Salud**: banner con guía para activarlo en Ajustes.
- **Cargando**: skeletons en las tarjetas.
- **Error de lectura**: mensaje no intrusivo + reintentar.

## 3. GoalForm (crear / editar)

Formulario simple, crear en < 30 segundos.

**Campos:**
1. **Tipo de objetivo** (selector con íconos: pasos, distancia, calorías, ejercicio, peso).
2. **Título** (autocompletado según tipo, editable).
3. **Meta** (`targetValue`) con la unidad correspondiente + stepper/teclado numérico.
4. **Período** (diario / semanal) — para peso se fija en `target` + deadline opcional.
5. **Para peso**: valor de partida (`startValue`, pre-cargado con último peso de Health).
6. **Recordatorio**: toggle + selector de hora.

- Validaciones: meta > 0, título no vacío, deadline futura.
- Botones: Guardar / Cancelar. En edición: opción **Eliminar**.
- Al guardar: persistir en SwiftData + (re)programar notificación.

## 4. GoalDetail

Detalle e historia de un objetivo.

- Progreso grande (anillo/barra) con valor actual vs meta.
- **Gráfico de los últimos 7 días** (Swift Charts: barras para acumulativos, línea
  para peso).
- Datos: mejor día, promedio, racha (post-MVP).
- Acciones: Editar, Activar/Pausar, Eliminar, toggle recordatorio.

## 5. Settings

- Estado de permisos (Salud, Notificaciones) + accesos directos a Ajustes del sistema.
- Switch global de notificaciones.
- Unidades (si aplica) / idioma.
- Acerca de / versión / privacidad.

## Sistema de diseño

- **SwiftUI** + **SF Symbols** para íconos de cada tipo.
- Paleta: un color de acento + colores semánticos por estado (progreso/completado).
- Componentes reutilizables: `ProgressRing`, `GoalCard`, `MetricChart`, `EmptyState`.
- Soporte **Dark Mode** desde el día 1.
- **Dynamic Type** y accesibilidad (ver doc 06).

## Principios de UX

1. **Glanceable**: entender el estado en < 3 segundos.
2. **Cero fricción** para crear un objetivo.
3. **Feedback inmediato**: animaciones de progreso al actualizar.
4. **Tono motivador** en copys y notificaciones.
5. **Confianza**: claridad sobre qué datos se usan y que no salen del teléfono.

## Navegación

- `NavigationStack` (SwiftUI) con el Dashboard como raíz.
- `sheet` para `GoalForm` (modal).
- `push` para `GoalDetail`.
- Deep link desde notificación → abre `GoalDetail` del goal.
