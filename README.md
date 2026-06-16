# Crazyflie Flight Control

**Tesis:** Desarrollo de un Sistema de Vuelo Autónomo y Guiado por Teleoperación para el Dron Crazyflie 2.0 mediante Control PID, Visión Artificial e Interfaz Gráfica en Python

---

## Descripción General

Sistema de control de vuelo para el nano-cuadricóptero Crazyflie 2.0 con dos modalidades de operación:

- **Modo Autónomo:** el dron despega, se eleva y mantiene posición de forma completamente automática usando PID y visión computacional.
- **Modo Teleoperado (PS4):** el operador controla la aeronave mediante un mando de PS4 con asistencia de control de altitud (altitude hold).

Toda la operación se gestiona desde una interfaz gráfica (GUI) desarrollada en Python 3 para computadora de escritorio.

---

## Arquitectura de Control

### Altitud (Eje Z)
- Sensor: barómetro LPS25H integrado en el Crazyflie 2.0
- Control: lazo PID compartido entre modo autónomo y modo PS4
- Calibración: al iniciar cualquier modo, el sistema toma 200 muestras del barómetro (~4 s a 50 Hz) y establece el promedio como referencia cero
  
### Posición (Ejes X, Y)
- Sensor: cámara deportiva cenital (tipo GoPro) instalada en el techo
- Control: lazo PID de posición activo únicamente en modo autónomo
- Detección: color tracking sobre marcador rosa en la parte superior del dron
- Transición: el control PID de posición se activa automáticamente cuando la visión detecta al dron en cuadro

---

## Sistema de Visión Computacional

- Captura de video desde cámara cenital con OpenCV
- Seguimiento por color (color tracking) del marcador rosa
- Slider de zoom digital en la GUI para ajustar encuadre
- El procesamiento de video continúa activo aunque el usuario cambie de pestaña

---

## Interfaz Gráfica (GUI)

Desarrollada en Python 3 con las siguientes librerías:

| Librería | Rol |
|----------|-----|
| `tkinter` | Ventana principal, botones, sliders, labels, topbar |
| `matplotlib` (TkAgg) | Gráficas en tiempo real (altitud y potencia de motores) |
| `opencv (cv2)` | Captura y procesamiento de imágenes |
| `Pillow (PIL)` | Conversión de frames para despliegue en Tkinter |

### Pestañas
- **Principal:** selección de modo, gráfica de altitud (real vs setpoint), gráfica de potencia por motor
- **Cámara:** conexión/desconexión de video, transmisión en vivo, slider de zoom

---

## Comunicación y Telemetría

- **Hardware:** dongle USB Crazyradio PA (2.4 GHz)
- **Librería:** `cflib` (Bitcraze oficial)
- **URI de conexión:** `radio://0/80/2M/E7E7E7E701`
- **Telemetría:** arquitectura `LogConfig` para monitorear potencia de motores y barómetro en tiempo real

---

## Seguridad

El sistema incluye un botón de **Paro de Emergencia** en la GUI. Al activarse, corta inmediatamente la potencia de los 4 motores al 0%. Este protocolo es estrictamente manual y depende del criterio del operador.

---

## Estructura del Repositorio
---

## Requisitos

- Python 3.x
- cflib
- opencv-python
- Pillow
- matplotlib
- pygame (input PS4)
