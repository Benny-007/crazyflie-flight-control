# Spec: Visión Computacional — Crazyflie 2.0
**Versión:** 1.1  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Detectar y rastrear la posición del Crazyflie 2.0 en el plano XY mediante
procesamiento de video de una cámara cenital, para alimentar el lazo PID de
posición en modo autónomo.

---

## 2. Hardware

| Parámetro | Valor |
|-----------|-------|
| Cámara | GoPro o equivalente |
| Posición | Cenital (techo), apuntando hacia el área de vuelo |
| Interfaz | USB, captura vía OpenCV |
| Marcador visual | Color rosa en la parte superior del dron |

---

## 3. Pipeline de Procesamiento

1. Captura de frame desde la cámara vía OpenCV
2. Aplicación de zoom digital fijo (`CAM_ZOOM`) en `_procesar_frame`
3. Conversión de espacio de color para detección por rango HSV
4. Detección del marcador rosa por color tracking
5. Cálculo del centroide del objeto detectado
6. Conversión de coordenadas píxel → error de posición respecto al centro del frame
7. Entrega del error al lazo PID de posición XY

---

## 4. Parámetros

| Parámetro | Valor | Notas |
|-----------|-------|-------|
| Color objetivo | Rosa | Marcador físico en el dron |
| Método de detección | Color tracking (rango HSV) | |
| Referencia de posición | Centro del frame | Setpoint del PID XY |
| `CAM_ZOOM` | 48 | Zoom digital fijo en `_cfg`, no ajustable desde GUI |

### Nota sobre el zoom
El zoom digital es un valor estático definido en la configuración (`_cfg`).
No existe slider de zoom en la GUI actual — `CAM_ZOOM: 48` se aplica
directamente en `_procesar_frame` sin rango mínimo/máximo expuesto al usuario.

---

## 5. Lógica de Activación

- El procesamiento de video corre **continuamente** desde que se conecta la cámara
- El lazo PID de posición XY se activa **únicamente** cuando el algoritmo
  detecta al dron dentro del cuadro
- Mientras el dron no sea detectado (fase de despegue inicial), el control
  de posición permanece inactivo

---

## 6. Restricciones

- El dron no es visible en tierra debido a la altura de instalación de la cámara
- El procesamiento continúa activo aunque el usuario cambie de pestaña en la GUI
- La detección depende de las condiciones de iluminación del área de vuelo
- El zoom no es ajustable desde la GUI — requiere modificar `CAM_ZOOM` en `_cfg`

---

## 7. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Captura y procesamiento OpenCV | ✅ Implementado |
| Color tracking (marcador rosa) | ✅ Implementado |
| Zoom digital fijo (CAM_ZOOM=48) | ✅ Implementado |
| Activación automática del PID XY | ✅ Implementado |
| Slider de zoom ajustable en GUI | ❌ No implementado |
