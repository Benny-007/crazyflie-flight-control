# Spec: Interfaz Gráfica (GUI) — Crazyflie 2.1 Brushless
**Versión:** 1.3  
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
| `Pillow (PIL)` | Uso a confirmar tras retirar la pestaña de cámara |

⚠️ **`opencv (cv2)` ya no es necesario** — dependía de la pestaña de cámara,
ahora obsoleta (ver §3 y SPEC.md §3-4).

---

## 3. Estructura de Pestañas

### Pestaña Principal
- Botones de selección de modo: **Modo Autónomo** / **Modo PS4**
- Botón de **Paro de Emergencia** (rojo, visible en todo momento)
- Botón de **Salir** — cierra la aplicación de forma segura
- Panel de estado del sistema (ver §4)
- Gráficas en tiempo real (ver §5)
- Log de eventos con hora (ver §6)

### Pestaña Cámara — 🗄️ DEPRECADA
> El proyecto migró a posicionamiento por Lighthouse V2. La pestaña de
> cámara (conexión de video, transmisión en vivo, slider de zoom) queda
> obsoleta. Se define una nueva sección de estado de Lighthouse cuando el
> hardware esté configurado (ver §7).

---

## 4. Panel de Estado

### Chips de Estado
| Chip | Color | Significado |
|------|-------|-------------|
| Conexión | Verde | Crazyflie conectado |
| Conexión | Gris | Sin conexión |
| ARMADO | Naranja | Motores armados |
| Modo | — | MANUAL / ALTITUD (submodos de PS4, ver SPEC.md §2) |
| PRECISIÓN | — | ⏳ Pendiente redefinir — dependía de detección por cámara; su significado en el contexto de Lighthouse aún no se especifica |

### Lecturas en Tiempo Real
| Elemento | Descripción | Fuente (LogConfig) |
|----------|-------------|---------------------|
| Batería | Barra con % y voltaje. Rojo bajo 3.50 V → aterrizar | `pm.vbat` (agregar a LogConfig, ver §8) |
| Link | Calidad del enlace de radio en % | Por definir — cflib expone `link_quality` vía callback de conexión |
| Cronómetro | Tiempo de vuelo acumulado | Calculado en app, no requiere LogConfig |
| Roll / Pitch / Yaw | Actitud real del dron | `stabilizer.roll`, `stabilizer.pitch`, `stabilizer.yaw` |
| Altitud | Altitud actual y objetivo (en modo altitud) | `baro.asl` |
| Estado supervisor | "listo para armar", "volando", "VOLCADO", "BLOQUEADO" | `supervisor.info` o equivalente (confirmar en firmware) |

---

## 5. Gráficas en Tiempo Real

Muestran los últimos 60 segundos de datos:

| Gráfica | Variables | Propósito |
|---------|-----------|-----------|
| Altitud | `baro_filtered` vs `alt_setpoint` | Monitorear PID de altitud |
| Batería | Voltaje de batería (`pm.vbat`) | Detectar batería baja |
| Thrust | Thrust enviado | Diagnosticar comportamiento del vuelo |

---

## 6. Log de Eventos

- Muestra todos los eventos del sistema con hora
- Ejemplos: conexión, armado, desarmado, paro de emergencia, batería baja,
  desarmado automático por firmware
- Persiste aunque el usuario cambie de pestaña

---

## 7. Posicionamiento (Lighthouse V2) — ⏳ Pendiente de Definir

El proyecto usará dos estaciones base Lighthouse V2 para posicionamiento,
en reemplazo de la cámara cenital. Esta sección se completará una vez
configurado el hardware. Pendiente definir:

- Indicador de estado de las estaciones base en el panel
- Visualización de posición XYZ (¿reemplaza la pestaña de Cámara?)
- Relación entre el chip "PRECISIÓN" y la calidad de la señal Lighthouse

---

## 8. Topbar

| Elemento | Función |
|----------|---------|
| Botón Export CSV | Exportación manual del log de telemetría |

---

## 9. LogConfig

⚠️ **Requiere actualización** para incluir batería y estado del supervisor,
que el panel de estado (§4) necesita mostrar.

| LogConfig | Variables | Estado |
|-----------|-----------|--------|
| `lc` | `baro.asl`, potencia M1, M2, M3, M4 | ✅ Implementado |
| `lc_mot` | `stabilizer.roll`, `stabilizer.pitch` | ✅ Implementado |
| `lc_bat` | `pm.vbat` | ⏳ Pendiente — necesario para indicador de batería |
| `lc_sup` | Estado del supervisor | ⏳ Pendiente — confirmar variable exacta en firmware |

Respetar el límite de 26 bytes del protocolo CRTP por bloque de LogConfig.

---

## 10. Botón Salir

- Disponible en la pestaña principal en todo momento
- Al presionarlo: detiene todos los hilos activos, cierra el CSV logger,
  desconecta el Crazyflie y cierra la ventana
- Si el dron está en vuelo, el botón de salir **no actúa** hasta que el
  dron haya aterrizado o se haya activado el paro de emergencia

---

## 11. Restricciones

⚠️ **Bug conocido de Tkinter en este equipo:** no usar emojis de color
(⏱ 💾 ✔ ✖ ‼ ⚠) en textos de la interfaz — provocan crash de la librería.
Los símbolos △ ○ □ sí son seguros.

- La GUI corre en el hilo principal — el loop de control corre en hilo separado
- El paro de emergencia tiene prioridad sobre cualquier otra acción
- El botón salir no puede usarse durante el vuelo sin antes detener el dron

---

## 12. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Ventana principal con pestañas | ✅ Implementado |
| Panel de estado con chips | ⏳ Pendiente |
| Gráficas en tiempo real (altitud, batería, thrust) | ⏳ Pendiente |
| Log de eventos con hora | ⏳ Pendiente |
| Pestaña de cámara | 🗄️ Deprecada — retirar del código |
| Slider de zoom digital | 🗄️ Deprecado — retirar del código |
| Botón de paro de emergencia | ✅ Implementado |
| Export CSV desde topbar | ✅ Implementado |
| LogConfig batería (`lc_bat`) | ⏳ Pendiente |
| LogConfig supervisor (`lc_sup`) | ⏳ Pendiente |
| Botón Salir | ⏳ Pendiente |
| Cronómetro de vuelo | ⏳ Pendiente |
| Sección de estado Lighthouse V2 | ⏳ Pendiente — hardware sin configurar |
