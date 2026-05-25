# 00 — Visión y objetivos

## Problema

Las personas que quieren mejorar sus hábitos de salud y fitness suelen tener datos
dispersos (pasos, entrenamientos, peso) en la app de Salud de iOS, pero **no tienen
una forma simple de fijarse metas concretas y hacerles seguimiento**. La app de
Salud muestra datos, pero no está orientada a *objetivos personales con recordatorios*.

## Propuesta de valor

GoalFit convierte los datos de HealthKit en **objetivos accionables**:

- Definís una meta clara y medible (ej: "10.000 pasos por día", "perder 3 kg en 2 meses").
- GoalFit lee tus datos reales de Salud y calcula el progreso automáticamente.
- Recibís notificaciones que te mantienen al día y te motivan.
- Ves todo en un dashboard simple con anillos/barras de progreso.

> Diferencial: foco en **metas + seguimiento + motivación**, no en registrar datos
> manualmente (eso ya lo hace Salud/Apple Watch).

## Usuarios objetivo

- Personas con iPhone (y opcionalmente Apple Watch) que ya generan datos de salud.
- Nivel de fitness: principiante a intermedio que busca constancia.
- Quieren simplicidad, no una app compleja de coaching.

## Objetivos del producto

1. **Setear objetivos** de distintos tipos a partir de métricas de HealthKit.
2. **Sincronizar progreso** automáticamente con datos reales de Salud.
3. **Notificar** recordatorios y logros para sostener la motivación.
4. **Visualizar** estado y progreso en un dashboard claro.

## Tipos de objetivos soportados (MVP)

| Métrica | Unidad | Tipo de meta | Ejemplo |
|---------|--------|--------------|---------|
| Pasos | pasos/día | Diaria recurrente | 10.000 pasos diarios |
| Distancia caminando/corriendo | km/día o km/semana | Recurrente | 5 km por día |
| Calorías activas | kcal/día | Recurrente | 500 kcal diarias |
| Minutos de ejercicio | min/día | Recurrente | 30 min de ejercicio |
| Peso corporal | kg | Meta de objetivo (target) | Llegar a 70 kg |

## Tipos de objetivo (futuro / post-MVP)

- Frecuencia de entrenamientos por semana (ej: 4 workouts/semana).
- Horas de sueño.
- Hidratación / agua.
- Frecuencia cardíaca en reposo (tendencia).
- Objetivos de subida/mantenimiento de peso.

## Alcance

### Dentro del MVP

- Onboarding + permisos de HealthKit y notificaciones.
- Crear, editar y eliminar objetivos (de los 5 tipos del MVP).
- Lectura de datos de HealthKit y cálculo de progreso.
- Dashboard con lista de objetivos y su progreso.
- Detalle de objetivo con progreso histórico (últimos 7 días).
- Notificaciones de recordatorio diario y de logro de meta.
- Persistencia local de los objetivos.

### Fuera del MVP (futuro)

- Cuenta de usuario y sincronización en la nube (iCloud/CloudKit).
- Compartir progreso / social / retos con amigos.
- Widgets de pantalla de inicio y complicaciones de Apple Watch.
- App nativa de watchOS.
- Estadísticas avanzadas, rachas (streaks) y gamificación.
- Recomendaciones inteligentes / coaching.

## Métricas de éxito

- % de usuarios que crean al menos 1 objetivo tras el onboarding.
- Retención D7 / D30.
- % de objetivos con progreso actualizado en los últimos 3 días (uso activo).
- Tasa de objetivos completados.

## Principios de diseño

1. **Simplicidad primero**: crear un objetivo en menos de 30 segundos.
2. **Datos automáticos**: el usuario no debería cargar datos a mano si HealthKit los tiene.
3. **Privacidad**: los datos de salud nunca salen del dispositivo en el MVP.
4. **Motivación sin culpa**: notificaciones útiles, no spam ni mensajes negativos.
