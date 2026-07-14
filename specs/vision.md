# Spec: Visión Computacional — Crazyflie 2.0/2.1 [DEPRECADO]

> ⚠️ **MÓDULO DEPRECADO — junio 2026.** El proyecto migró de cámara cenital
> + color tracking a **posicionamiento por Lighthouse V2** (ver SPEC.md §3-4
> y el futuro `specs/positioning.md`, aún sin crear porque el hardware
> Lighthouse no está configurado). Este documento se conserva como registro
> histórico de la arquitectura anterior. **No usar como referencia para
> nueva implementación.** Ninguna variable aquí descrita (CAM_ZOOM,
> CAM_SIGN_X/Y, marcador rosa) debe aparecer en código nuevo.

**Versión:** 1.1 (congelada)  
**Estado:** Deprecado  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito (histórico)

Detectar y rastrear la posición del Crazyflie en el plano XY mediante
procesamiento de video de una cámara cenital, para alimentar el lazo PID de
posición en modo autónomo. **Reemplazado por Lighthouse V2.**

---

## 2. Hardware (histórico)

| Parámetro | Valor |
|-----------|-------|
| Cámara | GoPro o equivalente |
| Posición | Cenital (techo), apuntando hacia el área de vuelo |
| Interfaz | USB, captura vía OpenCV |
| Marcador visual | Color rosa en la parte superior del dron |

---

## 3. Pipeline de Procesamiento (histórico)

1. Captura de frame desde la cámara vía OpenCV
2. Aplicación de zoom digital (`CAM_ZOOM`) en `_procesar_frame`
3. Conversión de espacio de color para detección por rango HSV
4. Detección del marcador rosa por color tracking
5. Cálculo del centroide del objeto detectado
6. Conversión de coordenadas píxel → error de posición respecto al centro del frame
7. Entrega del error al lazo PID de posición XY

---

## 4. Parámetros (histórico)

| Parámetro | Valor | Notas |
|-----------|-------|-------|
| Color objetivo | Rosa | Marcador físico en el dron |
| Método de detección | Color tracking (rango HSV) | |
| `CAM_ZOOM` | 48 | Zoom digital, slider planeado pero nunca implementado |

---

## 5. Por Qué se Reemplazó

- Dependencia de condiciones de iluminación
- Requería calibración de zoom por sesión
- Cobertura limitada al área bajo la cámara
- Lighthouse V2 ofrece posicionamiento 3D más preciso y no depende de luz
  ambiental ni de un marcador de color

---

## 6. Estado de Implementación (histórico, al momento de deprecar)

| Componente | Estado |
|------------|--------|
| Captura y procesamiento OpenCV | ✅ Implementado (código legado) |
| Color tracking (marcador rosa) | ✅ Implementado (código legado) |
| Slider de zoom digital en GUI | ⏳ Nunca completado |
| Activación automática del PID XY | ✅ Implementado (código legado) |
