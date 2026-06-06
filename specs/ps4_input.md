# Spec: Input PS4 — Crazyflie 2.0
**Versión:** 1.0  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Gestionar la lectura del mando PS4 y traducir sus entradas en comandos
de vuelo para el modo teleoperado del Crazyflie 2.0.

---

## 2. Hardware

| Parámetro | Valor |
|-----------|-------|
| Dispositivo | Control DualShock 4 (PS4) |
| Interfaz | USB |
| Librería | pygame |

---

## 3. Mapeo de Controles

| Control | Acción | Notas |
|---------|--------|-------|
| Joystick izquierdo (eje Y) | Modificar setpoint de altitud | Sube/baja la altura deseada bajo control PID |
| Joystick derecho (eje X) | Movimiento lateral (izquierda/derecha) | Control directo de posición |
| Joystick derecho (eje Y) | Movimiento frontal (adelante/atrás) | Control directo de posición |
| Botón X | Armar / apagar motores | Inicia y detiene el vuelo en modo PS4 |

---

## 4. Comportamiento

- El joystick izquierdo **modifica dinámicamente el setpoint** de altitud —
  el lazo PID se encarga de alcanzar y mantener la nueva altura
- El joystick derecho controla **directamente** la dirección de movimiento
  en el plano XY
- El botón X actúa como **toggle**: primer pulso arma los motores,
  segundo pulso los apaga de forma programada
- El paro de emergencia de la GUI tiene prioridad sobre cualquier
  entrada del mando en todo momento

---

## 5. Restricciones

- En modo PS4 el lazo PID de posición XY **no está activo** — el operador
  controla la dirección manualmente
- El lazo PID de altitud sí permanece activo (altitude hold)
- La lectura del mando se realiza en el mismo loop principal de la aplicación

---

## 6. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Lectura de joysticks vía pygame | ✅ Implementado |
| Mapeo de botones | ✅ Implementado |
| Altitude hold en modo PS4 | ✅ Implementado |
