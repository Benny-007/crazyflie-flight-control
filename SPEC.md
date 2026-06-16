# SPEC.md — Sistema de Vuelo Crazyflie 2.0
**Versión:** 1.0  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Especificación general del sistema de vuelo autónomo y teleoperado para el
nano-cuadricóptero Crazyflie 2.0. Este documento define la arquitectura,
módulos, interfaces y restricciones del proyecto. Toda implementación en
`app.py` debe ser consistente con lo descrito aquí.

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
└── safety             # Paro de emergencia
```
---

## 4. Interfaces de Hardware

| Componente | Interfaz | Notas |
|------------|----------|-------|
| Crazyflie 2.0 | Crazyradio PA (2.4 GHz) | URI: `radio://0/80/2M/E7E7E7E701` |
| Cámara cenital | USB / captura OpenCV | GoPro o equivalente, vista cenital |
| Control PS4 | USB / pygame | Joystick izquierdo = altitud, derecho = XY |
| Barómetro | LPS25H (integrado en CF) | Leído vía `baro.asl` con LogConfig |

---

## 5. Especificaciones por Módulo

Las especificaciones detalladas de cada módulo se encuentran en la carpeta
`specs/`:

| Archivo | Módulo |
|---------|--------|
| `specs/pid_control.md` | Control PID de altitud y posición |
| `specs/barometer.md` | Filtro EMA y calibración de barómetro |
| `specs/vision.md` | Pipeline de visión computacional |
| `specs/ps4_input.md` | Mapeo de botones y joysticks |
| `specs/gui.md` | Interfaz gráfica y telemetría |
| `specs/csv_logger.md` | Sistema de registro de datos |
| `specs/safety.md` | Protocolo de paro de emergencia |

---

## 6. Restricciones del Sistema

- El Crazyflie 2.0 **no cuenta con Flow Deck ni Z-ranger** — el control de
  altitud depende exclusivamente del barómetro LPS25H.
- El barómetro reporta altitud sobre el nivel del mar (~2341 m en Ciudad de
  México) — se requiere calibración relativa obligatoria antes de cada vuelo.
- El sistema de visión no detecta al dron en tierra debido a la altura de la
  cámara — el control de posición XY se activa únicamente cuando el dron es
  detectado en cuadro.
- No se utiliza `stateEstimate.z` — requiere sensores adicionales no
  disponibles en este hardware.

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

## 8. Datos y Registro

- Telemetría registrada en CSV automáticamente al iniciar vuelo
- Exportación manual disponible desde la GUI (botón en topbar)
- Variables registradas: timestamp, altitud real, setpoint, potencia por motor
- No se utiliza formato `.mat`

---

## 9. Seguridad

- Paro de emergencia disponible en todo momento desde la GUI
- Al activarse: potencia de los 4 motores → 0% de forma inmediata
- El protocolo es estrictamente manual — depende del criterio del operador
