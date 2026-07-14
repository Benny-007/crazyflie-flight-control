# Spec: Panel de Ajuste en Vivo (Tuning Panel) — Crazyflie 2.1 Brushless
**Versión:** 1.0  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Proveer una interfaz de sliders dentro de la GUI para ajustar parámetros de
control en tiempo real durante banco de pruebas, sin necesidad de detener
la app ni modificar el código. Es la herramienta principal para encontrar
experimentalmente los valores óptimos del CF 2.1 Brushless que la
simulación no puede determinar con precisión (trims, frenado de aterrizaje,
etc. — ver specs/pid_control.md §5 y specs/safety.md §4).

---

## 2. Estructura General

El panel se organiza en **6 secciones colapsables**, cada una representando
un área funcional del sistema. Todas viven en una pestaña dedicada
("Tuning") o en un panel lateral desplegable de la pestaña principal.

Al final del panel: botón **"Guardar valores actuales"** que imprime en el
log de la GUI y en consola los valores vigentes en formato Python, listos
para copiar a la configuración permanente del código.

---

## 3. Sección 1 — Altitud (PID principal)

| Parámetro | Rango | Valor inicial (simulación) |
|-----------|-------|------------------------------|
| HOVER_THRUST | 10000 – 25000 | 17500 |
| KP_ALT | 1000 – 6000 | 3885 |
| KI_ALT | 0 – 150 | 50 |
| KD_ALT | 500 – 6000 | 3100 |
| I_LIMIT_ALT | 1000 – 8000 | 5000 |

---

## 4. Sección 2 — Trims de Vuelo

| Parámetro | Rango | Valor inicial |
|-----------|-------|----------------|
| ROLL_TRIM | -5.0 – 5.0 | 0.0 (por calibrar) |
| PITCH_TRIM | -5.0 – 5.0 | 0.0 (por calibrar) |

---

## 5. Sección 3 — Aterrizaje / Frenado

| Parámetro | Rango | Valor inicial |
|-----------|-------|----------------|
| BRAKE_THRESHOLD | 0.02 – 0.15 m | 0.05 |
| BRAKE_THRUST | 10000 – 30000 | 17500 (punto de partida — ver specs/safety.md) |
| BRAKE_DURATION | 0.10 – 0.50 s | 0.20 |
| ROLL_TRIM_LAND | -5.0 – 5.0 | 0.0 (por calibrar) |
| PITCH_TRIM_LAND | -5.0 – 5.0 | 0.0 (por calibrar) |
| RAMP_DOWN_TIME | 1.0 – 5.0 s | 3.0 |

---

## 6. Sección 4 — Barómetro

| Parámetro | Rango | Valor inicial |
|-----------|-------|----------------|
| BARO_GAIN | 0.5 – 1.2 | 0.89 (heredado CF 2.0, por revalidar) |
| BARO_ALPHA | 0.1 – 0.9 | 0.5 |

---

## 7. Sección 5 — Control Manual PS4

| Parámetro | Rango | Valor inicial |
|-----------|-------|----------------|
| PS4_MAX_VZ | 0.2 – 1.5 m/s | 0.75 |
| PS4_MAX_VEL | 0.1 – 0.8 m/s | 0.30 |
| PS4_EXPO | 0.0 – 0.9 | 0.60 |
| PS4_DEADZONE | 0.02 – 0.20 | 0.08 |

---

## 8. Sección 6 — Posición XY (Lighthouse V2)

⏳ **Pendiente de activar hasta configurar el hardware Lighthouse V2**
(ver SPEC.md §3-4). Los sliders existen en la spec pero deben quedar
deshabilitados/ocultos en la GUI hasta entonces.

| Parámetro | Rango | Valor inicial |
|-----------|-------|----------------|
| KP_VX / KP_VY | 1.0 – 10.0 | 5.50 |
| KI_VX / KI_VY | 0 – 1.0 | 0.12 |
| KD_VX / KD_VY | 0 – 3.0 | 0.81 |
| MAX_ANGLE | 5.0 – 25.0° | 15.0 |

---

## 9. Botón "Guardar Valores Actuales"

- Al presionarlo, imprime en el log de la GUI y en consola un bloque de
  texto en formato Python con todos los valores actuales de los sliders,
  listo para copiar directamente a la configuración del código:

```python
_cfg = {
    'HOVER_THRUST': 17500,
    'KP_ALT': 3885, 'KI_ALT': 50, 'KD_ALT': 3100, 'I_LIMIT_ALT': 5000,
    'ROLL_TRIM': 0.0, 'PITCH_TRIM': 0.0,
    'BRAKE_THRESHOLD': 0.05, 'BRAKE_THRUST': 17500, 'BRAKE_DURATION': 0.20,
    'ROLL_TRIM_LAND': 0.0, 'PITCH_TRIM_LAND': 0.0, 'RAMP_DOWN_TIME': 3.0,
    'BARO_GAIN': 0.89, 'BARO_ALPHA': 0.5,
    'PS4_MAX_VZ': 0.75, 'PS4_MAX_VEL': 0.30, 'PS4_EXPO': 0.60, 'PS4_DEADZONE': 0.08,
}
```

- No escribe directamente al archivo de configuración — el usuario copia
  y pega manualmente para evitar sobrescribir valores validados por accidente

---

## 10. Restricciones de Seguridad

- Los sliders de la **Sección 1 (Altitud)** y **Sección 3 (Aterrizaje)**
  solo deben poder modificarse **antes de armar motores** o con el dron
  en banco de pruebas fijo — cambiar HOVER_THRUST o BRAKE_THRUST mid-vuelo
  es peligroso
- Los sliders de **Sección 5 (PS4)** sí pueden ajustarse en vuelo, ya que
  afectan solo la sensibilidad del control, no la estabilidad base
- El panel debe mostrar claramente cuáles valores son "de simulación,
  punto de partida" vs. "ya validados en banco" — usar un indicador visual
  (por ejemplo, color de fondo) que se actualice tras cada guardado

---

## 11. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Sección 1 — Altitud | ⏳ Pendiente |
| Sección 2 — Trims | ⏳ Pendiente |
| Sección 3 — Aterrizaje | ⏳ Pendiente |
| Sección 4 — Barómetro | ⏳ Pendiente |
| Sección 5 — PS4 | ⏳ Pendiente |
| Sección 6 — Posición XY | ⏳ Pendiente (bloqueada hasta Lighthouse) |
| Botón guardar valores | ⏳ Pendiente |
| Restricción de armado para sliders críticos | ⏳ Pendiente |
