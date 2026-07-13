# Spec: Interfaz Gráfica (GUI) — Crazyflie 2.1 Brushless
**Versión:** 1.2  
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
- Botón de **Paro de Emergencia** (rojo, visible en todo momento)
- Botón de **Salir** — cierra la aplicación de forma segura
- Panel de estado del sistema (ver §4)
- Gráficas en tiempo real (ver §5)
- Log de eventos con hora (ver §6)

### Pestaña Cámara
- Botón de conexión/desconexión del flujo de video
- Transmisión en vivo de la cámara cenital
- Slider de zoom digital (valor inicial: CAM_ZOOM=48)

---

## 4. Panel de Estado

El panel muestra el estado del sistema en tiempo real mediante chips visuales
y lecturas numéricas.

### Chips de Estado
| Chip | Color | Significado |
|------|-------|-------------|
| Conexión | Verde | Crazyflie conectado |
| Conexión | Gris | Sin conexión |
| ARMADO | Naranja | Motores armados |
| Modo | — | MANUAL / ALTITUD |
| PRECISION | — | Control de posición activo |

### Lecturas en Tiempo Real
| Elemento | Descripción |
|----------|-------------|
| Batería | Barra con % y voltaje. Rojo bajo 3.50 V → aterrizar |
| Link | Calidad del enlace de radio en % |
| Cronómetro | Tiempo de vuelo acumulado |
| Roll / Pitch / Yaw | Actitud real del dron |
| Altitud | Altitud actual y objetivo (en modo altitud) |
| Estado supervisor | "listo para armar", "volando", "VOLCADO", "BLOQUEADO" |

---

## 5. Gráficas en Tiempo Real

Muestran los últimos 60 segundos de datos:

| Gráfica | Variables | Propósito |
|---------|-----------|-----------|
| Altitud | `baro_filtered` vs `alt_setpoint` | Monitorear PID de altitud |
| Batería | Voltaje de batería | Detectar batería baja |
| Thrust | Thrust enviado | Diagnosticar comportamiento del vuelo |

- Renderizadas con `FigureCanvasTkAgg` y `FuncAnimation`
- Actualizadas en tiempo real durante el vuelo

---

## 6. Log de Eventos

- Muestra todos los eventos del sistema con hora
- Ejemplos: conexión, armado, desarmado, paro de emergencia, batería baja,
  desarmado automático por firmware
- Persiste aunque el usuario cambie de pestaña

---

## 7. Topbar

| Elemento | Función |
|----------|---------|
| Botón Export CSV | Exportación manual del log de telemetría |

---

## 8. LogConfig

La telemetría se divide en dos LogConfig para respetar el límite de 26 bytes
del protocolo CRTP:

| LogConfig | Variables |
|-----------|-----------|
| `lc` | `baro.asl`, potencia M1, M2, M3, M4 |
| `lc_mot` | `stabilizer.roll`, `stabilizer.pitch` |

`stabilizer.roll` y `stabilizer.pitch` son obligatorios para la compensación
de inclinación (tilt compensation) en el hover loop.

---

## 9. Botón Salir

- Disponible en la pestaña principal en todo momento
- Al presionarlo: detiene todos los hilos activos, cierra el CSV logger,
  desconecta el Crazyflie y cierra la ventana
- Si el dron está en vuelo, el botón de salir **no actúa** hasta que el
  dron haya aterrizado o se haya activado el paro de emergencia

---

## 10. Restricciones

⚠️ **Bug conocido de Tkinter en este equipo:** no usar emojis de color
(⏱ 💾 ✔ ✖ ‼ ⚠) en textos de la interfaz — provocan crash de la librería.
Los símbolos △ ○ □ sí son seguros.

- El procesamiento de video continúa activo aunque el usuario cambie de pestaña
- La GUI corre en el hilo principal — el loop de control corre en hilo separado
- El paro de emergencia tiene prioridad sobre cualquier otra acción
- El botón salir no puede usarse durante el vuelo sin antes detener el dron

---

## 11. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Ventana principal con pestañas | ✅ Implementado |
| Panel de estado con chips | ⏳ Pendiente |
| Gráficas en tiempo real (altitud, batería, thrust) | ⏳ Pendiente |
| Log de eventos con hora | ⏳ Pendiente |
| Pestaña de cámara | ✅ Implementado |
| Slider de zoom digital | ⏳ Pendiente |
| Botón de paro de emergencia | ✅ Implementado |
| Export CSV desde topbar | ✅ Implementado |
| LogConfig dividido (lc + lc_mot) | ✅ Implementado |
| Botón Salir | ⏳ Pendiente |
| Cronómetro de vuelo | ⏳ Pendiente |
| Indicador de batería con alerta | ⏳ Pendiente |
