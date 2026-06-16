# Spec: Interfaz Gráfica (GUI) — Crazyflie 2.0
**Versión:** 1.1  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Centralizar la operación, visualización de telemetría y control del sistema
de vuelo mediante una interfaz gráfica de escritorio desarrollada en Python 3.

---

## 2. Stack de Librerías

| Librería | Rol |
|----------|-----|
| `tkinter` | Ventana principal, botones, sliders, labels, topbar |
| `matplotlib` (backend TkAgg) | Gráficas en tiempo real embebidas en Tkinter |
| `opencv (cv2)` | Captura y procesamiento de video |
| `Pillow (PIL)` | Conversión de frames para despliegue en Tkinter |

---

## 3. Estructura de Pestañas

### Pestaña Principal
- Botones de selección de modo: **Modo Autónomo** / **Modo PS4**
- Gráfica en tiempo real: altitud real (barómetro) vs setpoint deseado
- Gráfica en tiempo real: potencia individual de los 4 motores
- Botón de **Paro de Emergencia**
- Botón de **Salir** — cierra la aplicación de forma segura

### Pestaña Cámara
- Botón de conexión/desconexión del flujo de video
- Transmisión en vivo de la cámara cenital
- Slider de zoom digital (valor inicial: CAM_ZOOM=48)

---

## 4. Topbar

| Elemento | Función |
|----------|---------|
| Botón Export CSV | Exportación manual del log de telemetría |

---

## 5. Gráficas en Tiempo Real

| Gráfica | Variables | Propósito |
|---------|-----------|-----------|
| Altitud | `baro_filtered` vs `alt_setpoint` | Monitorear desempeño del PID de altitud |
| Motores | Potencia M1, M2, M3, M4 | Diagnosticar anomalías en el vuelo |

- Renderizadas con `FigureCanvasTkAgg` y `FuncAnimation`
- Actualizadas en tiempo real durante el vuelo

---

## 6. LogConfig

La telemetría se divide en dos LogConfig para respetar el límite de 26 bytes
del protocolo CRTP:

| LogConfig | Variables |
|-----------|-----------|
| `lc` | `baro.asl`, potencia M1, M2, M3, M4 |
| `lc_mot` | `stabilizer.roll`, `stabilizer.pitch` |

`stabilizer.roll` y `stabilizer.pitch` son obligatorios para la compensación
de inclinación (tilt compensation) en el hover loop.

---

## 7. Botón Salir

- Disponible en la pestaña principal en todo momento
- Al presionarlo: detiene todos los hilos activos, cierra el CSV logger,
  desconecta el Crazyflie y cierra la ventana
- Si el dron está en vuelo, el botón de salir **no actúa** hasta que el
  dron haya aterrizado o se haya activado el paro de emergencia

---

## 8. Restricciones

- El procesamiento de video continúa activo aunque el usuario cambie de pestaña
- La GUI corre en el hilo principal — el loop de control corre en hilo separado
- El paro de emergencia tiene prioridad sobre cualquier otra acción
- El botón salir no puede usarse durante el vuelo sin antes detener el dron

---

## 9. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Ventana principal con pestañas | ✅ Implementado |
| Gráficas en tiempo real | ✅ Implementado |
| Pestaña de cámara | ✅ Implementado |
| Slider de zoom digital | ⏳ Pendiente |
| Botón de paro de emergencia | ✅ Implementado |
| Export CSV desde topbar | ✅ Implementado |
| LogConfig dividido (lc + lc_mot) | ✅ Implementado |
| Botón Salir | ⏳ Pendiente |
