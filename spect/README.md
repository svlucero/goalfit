# 📋 Spect — Planificación de GoalFit

Carpeta de especificación y planificación de **GoalFit**, una app iOS para setear
objetivos de salud/fitness, integrarse con la app de Salud de iOS (HealthKit),
enviar notificaciones y mostrar un dashboard de progreso.

> Issue origen: [#1 — Nueva app para setear objetivos](../../../issues/1)

## 🎯 Resumen ejecutivo

GoalFit permite al usuario definir metas medibles (pasos, distancia, calorías,
minutos de ejercicio, peso, etc.), las sincroniza automáticamente con los datos
reales de HealthKit, calcula el progreso y notifica al usuario para mantener la
motivación. Todo se visualiza en un dashboard claro.

## 📚 Índice de documentos

| # | Documento | Contenido |
|---|-----------|-----------|
| 00 | [Visión y objetivos](./00-vision-y-objetivos.md) | Problema, propuesta de valor, usuarios, alcance MVP vs futuro |
| 01 | [Arquitectura y stack](./01-arquitectura-y-stack.md) | Decisiones técnicas, capas, patrón, dependencias |
| 02 | [Modelo de datos](./02-modelo-de-datos.md) | Entidades, esquema de persistencia, relaciones |
| 03 | [Integración HealthKit](./03-integracion-healthkit.md) | Permisos, tipos de datos, lectura/observación, edge cases |
| 04 | [Notificaciones](./04-notificaciones.md) | Tipos, triggers, permisos, contenido, programación |
| 05 | [Dashboard y UX](./05-dashboard-y-ux.md) | Pantallas, flujos, componentes, estados |
| 06 | [Requisitos no funcionales](./06-requisitos-no-funcionales.md) | Privacidad, rendimiento, accesibilidad, testing, App Store |
| 07 | [Backlog por pasos](./07-backlog.md) | Roadmap incremental en milestones e issues accionables |

## 🧭 Cómo usar esta planificación

1. Leé `00` y `01` para entender el **qué** y el **cómo** a alto nivel.
2. Usá `02`–`06` como referencia técnica durante la implementación.
3. Seguí el **backlog (`07`)** de arriba hacia abajo: cada paso es un incremento
   funcional que se puede desarrollar y mergear de forma independiente.

## 🏷️ Estado

- [x] Planificación inicial
- [ ] Setup del proyecto Xcode
- [ ] MVP
- [ ] Beta (TestFlight)
- [ ] Release App Store
