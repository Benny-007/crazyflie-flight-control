# Crazyflie Flight Control

**Tesis:** Desarrollo de un Sistema de Vuelo Autónomo y Guiado por Teleoperación para el Dron Crazyflie 2.1 Brushless mediante Control PID, Visión Artificial e Interfaz Gráfica en Python

---

## Descripción General

Sistema de control de vuelo para el nano-cuadricóptero Crazyflie 2.1 Brushless con dos modalidades de operación:

- **Modo Autónomo:** el dron despega, se eleva y mantiene posición de forma completamente automática usando PID y visión computacional.
- **Modo Teleoperado (PS4):** el operador controla la aeronave mediante un mando de PS4 con asistencia de control de altitud (altitude hold).

Toda la operación se gestiona desde una interfaz gráfica (GUI) desarrollada en Python 3 para computadora de escritorio.

---

## Arquitectura de Control

### Altitud (Eje Z)
- Sensor: barómetro LPS22HH integrado en el Crazyflie 2.1
- Control: lazo PID compartido entre modo autónomo y modo PS4
- Calibración: 200 muestras del barómetro (~4 s a 50 Hz) antes de armar motores

### Posición (Ejes X, Y)
- Sensor: cámara deportiva cenital (tipo GoPro) instalada en el techo
- Control: lazo PID de posición activo únicamente en modo autónomo
- Detección: color tracking sobre marcador rosa en la parte superior del dron
- Transición: el control PID de posición se activa automáticamente cuando la visión detecta al dron en cuadro

---

## Armado de Motores

El Crazyflie 2.1 Brushless requiere armado explícito antes de volar:

- **△ Triángulo (PS4)** → arma motores (`supervisor.send_arming_request(True)`)
- **△ Triángulo (PS4)** nuevamente → desarma motores
- **○ Círculo / botón rojo GUI / tecla espacio** → paro de emergencia

---

## Sistema de Visión Computacional

- Captura de video desde cámara cenital con OpenCV
- Seguimiento por color (color tracking) del marcador rosa
- Zoom digital configurable (CAM_ZOOM=48)
- El procesamiento de video continúa activo aunque el usuario cambie de pestaña

---

## Interfaz Gráfica (GUI)

Desarrollada en Python 3 con las siguientes librerías:

| Librería | Rol |
|----------|-----|
| `tkinter` | Ventana principal, botones, sliders, labels, topbar |
| `matplotlib` (TkAgg) | Gráficas en tiempo real (altitud, batería, thrust) |
| `opencv (cv2)` | Captura y procesamiento de imágenes |
| `Pillow (PIL)` | Conversión de frames para despliegue en Tkinter |

### Pestañas
- **Principal:** selección de modo, panel de estado, gráficas, log de eventos, botón de paro de emergencia, botón salir
- **Cámara:** conexión/desconexión de video, transmisión en vivo, slider de zoom

### Panel de Estado
- Chips: conexión, ARMADO, modo, precisión
- Batería: % y voltaje (alerta roja < 3.50 V)
- Cronómetro de vuelo, actitud real, estado del supervisor

---

## Comunicación y Telemetría

- **Hardware:** dongle USB Crazyradio PA (2.4 GHz)
- **Librería:** `cflib` (Bitcraze oficial)
- **URI de conexión:** `radio://0/80/2M/E7E7E7E7E7`
- **Telemetría:** arquitectura `LogConfig` dividida en dos bloques (límite CRTP 26 bytes)

---

## Seguridad

- **Paro de emergencia:** botón rojo en GUI, ○ en PS4, o tecla espacio
- Corta motores al instante con `send_stop_setpoint()` y desarma el firmware
- Aterrizaje normal: rampa quíntica suave — nunca corte seco
- Batería < 3.50 V → aterrizar inmediatamente

---

## Diagnóstico de Conexión

```bash
# Verificar dongle
lsusb | grep 1915   # debe mostrar 1915:7777
```
- Si aparece `35f0:bad2` → reflashear el dongle
- Si aparece `radio://0/0/1M` en escaneo → ignorarlo, el dron real es `radio://0/80/2M`

---

## Estructura del Repositorio

```
crazyflie-flight-control/
├── app.py                  # Aplicación principal
├── SPEC.md                 # Especificación general del sistema
├── specs/                  # Especificaciones por módulo
│   ├── pid_control.md
│   ├── barometer.md
│   ├── vision.md
│   ├── ps4_input.md
│   ├── gui.md
│   ├── csv_logger.md
│   └── safety.md
├── simulation/             # Scripts de simulación MATLAB
├── docs/                   # Documentación y referencias
└── README.md
```

---

## Requisitos

```bash
pip install cflib opencv-python matplotlib pygame Pillow
```
