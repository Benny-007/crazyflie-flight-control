# SPEC.md — Sistema de Vuelo Crazyflie 2.1 Brushless
**Versión:** 1.2  
**Estado:** Borrador — valores de control en validación (ver specs/pid_control.md); sistema de posicionamiento en transición  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Especificación general del sistema de vuelo autónomo y teleoperado para el
nano-cuadricóptero Crazyflie 2.1 Brushless. Este documento define la
arquitectura, módulos, interfaces y restricciones del proyecto. Toda
implementación en `app.py` debe ser consistente con lo descrito aquí y con
las specs detalladas en `specs/`.

---

## 2. Modos de Operación

| Modo | Submodo | Descripción |
|------|---------|-------------|
| Autónomo | — | Despegue, elevación y mantenimiento de posición XYZ sin intervención del operador |
| PS4 | MANUAL | Control directo de ángulos por joystick, sin altitude hold |
| PS4 | ALTITUD | Altitude hold activo — joystick modifica el setpoint de altitud |

> Nota: los chips "MANUAL" / "ALTITUD" del panel de estado (specs/gui.md)
> son submodos del modo PS4, no modos independientes del modo Autónomo.

---

## 3. Arquitectura de Módulos

```
app.py
├── pid_control        # Lazos PID de altitud y posición
├── barometer          # Lectura, filtrado EMA y calibración
├── positioning         # ⏳ EN DEFINICIÓN — Lighthouse V2 (reemplaza a "vision")
├── ps4_input          # Lectura de joysticks y botones
├── gui                # Ventana principal, panel de estado, gráficas
├── telemetry          # LogConfig: barómetro, motores, actitud, batería
├── csv_logger         # Auto-guardado y exportación manual de datos
└── safety             # Armado, paro de emergencia y aterrizaje controlado
```

⚠️ **Cambio de arquitectura (junio 2026):** el proyecto migra del sistema de
visión por cámara cenital + color tracking a **posicionamiento por Lighthouse
V2** (dos estaciones base). El módulo `vision` queda **deprecado**;
`specs/vision.md` se conserva como registro histórico pero no debe usarse
como referencia para nueva implementación. El módulo `positioning` está
pendiente de definición completa — aún no se ha configurado el hardware
Lighthouse.

---

## 4. Interfaces de Hardware

| Componente | Interfaz | Notas |
|------------|----------|-------|
| Crazyflie 2.1 Brushless | Crazyradio PA (2.4 GHz) | URI: `radio://0/80/2M/E7E7E7E7E7` |
| Sistema de posicionamiento | Lighthouse V2 (2 estaciones base) | ⏳ Pendiente de configuración — reemplaza a la cámara cenital |
| Control PS4 | USB / pygame | △ arma/desarma, ○ emergencia, sticks XYZ |
| Barómetro | **BMP388** (integrado en CF 2.1 Brushless) | Leído vía `baro.asl` con LogConfig |

⚠️ **Corrección:** el sensor de presión del CF 2.1 Brushless es el **BMP388**
(alta precisión, Bosch Sensortec), no el LPS25H del CF 2.0 ni el LPS22HH.
Ver `specs/barometer.md` para detalles.

⚠️ **Ya no se usa cámara cenital ni marcador de color rosa.** Todo lo
relacionado a `specs/vision.md`, el slider de zoom, y CAM_ZOOM/CAM_SIGN_*
queda obsoleto. Se documentará el reemplazo en un nuevo
`specs/positioning.md` una vez configurado el hardware Lighthouse.

---

## 5. Especificaciones por Módulo

| Archivo | Módulo | Estado |
|---------|--------|--------|
| `specs/pid_control.md` | Control PID de altitud y posición — **fuente de verdad para valores numéricos** | ✅ Vigente |
| `specs/barometer.md` | Filtro EMA y calibración de barómetro | ✅ Vigente |
| `specs/vision.md` | Pipeline de visión por cámara (color tracking) | 🗄️ **Deprecado** — reemplazado por Lighthouse V2 |
| `specs/positioning.md` | Posicionamiento por Lighthouse V2 | ⏳ **Pendiente de crear** — hardware aún sin configurar |
| `specs/ps4_input.md` | Mapeo de botones y joysticks | ✅ Vigente |
| `specs/gui.md` | Interfaz gráfica y telemetría | ✅ Vigente (revisar referencias a cámara) |
| `specs/csv_logger.md` | Sistema de registro de datos | ✅ Vigente |
| `specs/safety.md` | Armado, paro de emergencia y aterrizaje controlado | ✅ Vigente |

> ⚠️ **Regla de precedencia:** si un valor numérico de control (PID, thrust,
> trims) difiere entre este archivo y `specs/pid_control.md`, **prevalece
> `specs/pid_control.md`**, que se actualiza primero tras cada simulación
> o vuelo de prueba.

---

## 6. Restricciones del Sistema

- El Crazyflie 2.1 Brushless **no gira motores hasta recibir armado explícito**
  vía `supervisor.send_arming_request(True)`
- El firmware puede desarmarse automáticamente por volteo o timeout
- El barómetro (BMP388) requiere calibración relativa de 200 muestras
  (~4 s a 50 Hz) antes de cada vuelo
- El control de posición XY en modo autónomo depende del sistema Lighthouse
  V2, **actualmente sin configurar** — el modo autónomo con posición no es
  funcional hasta completar esa configuración
- No se utiliza `stateEstimate.z` — requiere sensores adicionales no disponibles
- ⚠️ No usar emojis de color en la GUI — provocan crash de Tkinter en este equipo

---

## 7. Comportamiento Esperado del Sistema

| Métrica | Valor objetivo |
|---------|---------------|
| RMSE en hover (altitud) | < 10 cm |
| Overshoot en escalón de 1 m | < 25% |
| Tiempo de establecimiento | < 3 s |
| Frecuencia del loop de control | 50 Hz |
| Muestras de calibración barómetro | 200 muestras (~4 s a 50 Hz) |

---

## 8. Parámetros Clave del Sistema

⚠️ **Estos valores son un resumen de referencia rápida. Para el detalle
completo, justificación y estado de validación, consultar
`specs/pid_control.md` v1.3 — ese archivo es la fuente de verdad.**

| Parámetro | Valor | Estado |
|-----------|-------|--------|
| URI | `radio://0/80/2M/E7E7E7E7E7` | ✅ Confirmado |
| LOOP_HZ | 50 | ✅ Confirmado |
| HOVER_THRUST (PWM) | ~17500 | ⏳ De simulación, validar en banco |
| THRUST_MIN | 8000 | ⏳ De simulación, validar en banco |
| THRUST_MAX | 60000 | ✅ Confirmado |
| KP_ALT | 3885.0 | ⏳ De simulación, validar en banco |
| KI_ALT | 50.0 | ✅ Confirmado |
| KD_ALT | 3100.0 | ⏳ De simulación, validar en banco |
| BARO_GAIN | 0.89 (CF 2.0) | ⏳ Por revalidar con BMP388 |

---

## 9. Datos y Registro

- Telemetría registrada en CSV automáticamente al iniciar vuelo
- Exportación manual disponible desde la GUI (botón en topbar)
- Variables registradas: timestamp, altitud real, setpoint, potencia por
  motor, voltaje de batería, thrust total (ver `specs/csv_logger.md`)
- No se utiliza formato `.mat`

---

## 10. Diagnóstico de Conexión

- Verificar dongle: `lsusb | grep 1915` debe mostrar `1915:7777`
- Si aparece `35f0:bad2` → reflashear el dongle
- Si aparece `radio://0/0/1M` en el escaneo → ignorarlo, es un fantasma;
  el dron real opera en `radio://0/80/2M`
- Batería del dron por USB: M3 azul parpadeando = cargando;
  M2 y M3 fijos = cargada completamente

---

## 11. Seguridad

- Paro de emergencia: botón rojo en GUI, ○ en PS4, o tecla espacio
- Al activarse: `send_stop_setpoint()` + `send_arming_request(False)`
- El protocolo es estrictamente manual — depende del criterio del operador
- Batería por debajo de 3.50 V → aterrizar inmediatamente
- Ver `specs/safety.md` para el protocolo completo de aterrizaje controlado
