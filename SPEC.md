# SPEC.md — Sistema de Vuelo Crazyflie 2.1 Brushless
**Versión:** 1.1  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Especificación general del sistema de vuelo autónomo y teleoperado para el
nano-cuadricóptero Crazyflie 2.1 Brushless. Este documento define la
arquitectura, módulos, interfaces y restricciones del proyecto. Toda
implementación en `app.py` debe ser consistente con lo descrito aquí.

---

## 2. Modos de Operación

| Modo | Descripción |
|------|-------------|
| Autónomo | Despegue, elevación y mantenimiento de posición XYZ sin intervención del operador |
| PS4 | Teleoperación asistida con altitude hold via joystick |

---

## 3. Arquitectura de Módulos

```
app.py
├── pid_control        # Lazos PID de altitud y posición
├── barometer          # Lectura, filtrado EMA y calibración
├── vision             # Captura, procesamiento y tracking de color
├── ps4_input          # Lectura de joysticks y botones
├── gui                # Ventana principal, gráficas y pestaña de cámara
├── telemetry          # LogConfig: barómetro y potencia de motores
├── csv_logger         # Auto-guardado y exportación manual de datos
└── safety             # Armado, paro de emergencia y aterrizaje controlado
```

---

## 4. Interfaces de Hardware

| Componente | Interfaz | Notas |
|------------|----------|-------|
| Crazyflie 2.1 Brushless | Crazyradio PA (2.4 GHz) | URI: `radio://0/80/2M/E7E7E7E7E7` |
| Cámara cenital | USB / captura OpenCV | GoPro o equivalente, vista cenital |
| Control PS4 | USB / pygame | △ arma/desarma, ○ emergencia, sticks XYZ |
| Barómetro | LPS22HH (integrado en CF 2.1) | Leído vía `baro.asl` con LogConfig |

---

## 5. Especificaciones por Módulo

| Archivo | Módulo |
|---------|--------|
| `specs/pid_control.md` | Control PID de altitud y posición |
| `specs/barometer.md` | Filtro EMA y calibración de barómetro |
| `specs/vision.md` | Pipeline de visión computacional |
| `specs/ps4_input.md` | Mapeo de botones y joysticks |
| `specs/gui.md` | Interfaz gráfica y telemetría |
| `specs/csv_logger.md` | Sistema de registro de datos |
| `specs/safety.md` | Armado, paro de emergencia y aterrizaje controlado |

---

## 6. Restricciones del Sistema

- El Crazyflie 2.1 Brushless **no gira motores hasta recibir armado explícito**
  via `supervisor.send_arming_request(True)`
- El firmware puede desarmarse automáticamente por volteo o timeout
- El barómetro reporta altitud sobre el nivel del mar (~2341 m en Ciudad de
  México) — se requiere calibración relativa de 200 muestras antes de cada vuelo
- El sistema de visión no detecta al dron en tierra — el control de posición
  XY se activa únicamente cuando el dron es detectado en cuadro
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

| Parámetro | Valor |
|-----------|-------|
| URI | `radio://0/80/2M/E7E7E7E7E7` |
| LOOP_HZ | 50 |
| HOVER_THRUST | 55000 |
| THRUST_MIN | 20000 |
| THRUST_MAX | 60000 |
| BARO_GAIN | 0.89 |
| KP_ALT | 3750.0 |
| KI_ALT | 50.0 |
| KD_ALT | 5250.0 |

---

## 9. Datos y Registro

- Telemetría registrada en CSV automáticamente al iniciar vuelo
- Exportación manual disponible desde la GUI (botón en topbar)
- Variables registradas: timestamp, altitud real, setpoint, potencia por motor
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
