# Spec: Control PID — Crazyflie 2.1 Brushless
**Versión:** 1.3  
**Estado:** Borrador — valores en validación  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Mantener altitud objetivo (eje Z) y posición (ejes X, Y) mediante lazos PID
implementados en Python. El control de altitud opera en ambos modos (autónomo
y PS4). El control de posición XY opera únicamente en modo autónomo.

---

## 2. Control de Altitud (Eje Z)

### Parámetros — CF 2.1 Brushless (de simulación, pendientes de banco)

⚠️ **Origen de los valores:** obtenidos mediante simulación MATLAB
(`simulation/sim_crazyflie_brushless.m`) con mapeo PWM→thrust lineal
aproximado. **Deben validarse en banco de pruebas antes de considerarse
definitivos.**

| Parámetro | CF 2.0 (validado en vuelo) | CF 2.1 BL (simulación) | Notas |
|-----------|---------------------------|------------------------|-------|
| KP_ALT | 3750.0 | 3885.0 | Casi sin cambio |
| KI_ALT | 50.0 | 50.0 | Sin cambio |
| KD_ALT | 5250.0 | 3100.0 | ⚠️ Menor: el brushless responde más rápido y KD alto amplifica ruido del barómetro |
| I_LIMIT_ALT | 5000.0 | 5000.0 | Sin cambio |
| HOVER_THRUST | 55000 | **~17500** | ⚠️ **CRÍTICO** — el brushless tiene ratio empuje/peso ~3.75:1; usar 55000 provocaría ascenso descontrolado |
| THRUST_MIN | 20000 | 8000 | Ajustado al nuevo punto de operación |
| THRUST_MAX | 60000 | 60000 | Sin cambio |
| TARGET_ALTITUDE | 0.5 m | 0.5 m | Sin cambio |
| BARO_GAIN | 0.89 | Por validar | Puede cambiar con el LPS22HH |
| LOOP_HZ | 50 | 50 | Sin cambio |
| RAMP_UP_TIME | 1.0 s | 1.0 s | Sin cambio |
| RAMP_DOWN_TIME | 3.0 s | 3.0 s | Sin cambio |
| HOLD_TIME | 5.0 s | 5.0 s | Sin cambio |

### Resultados de simulación (CF 2.1 BL, ganancias recomendadas)

| Métrica | Valor simulado | Objetivo |
|---------|---------------|----------|
| Margen de fase | 76.7° | > 45° ✅ |
| Overshoot | 7.5% | < 25% ✅ |
| Tiempo de establecimiento | ~3.5 s | < 3 s (marginal) |
| RMSE en hover (lineal discreto) | 2.0 cm | < 10 cm ✅ |
| RMSE en hover (no lineal 6 DOF) | 1.0 cm | < 10 cm ✅ |

### Manejo de dt

| Contexto | dt | Método |
|----------|----|--------|
| `_takeoff`, `_land`, `_open_loop_run` | 0.02 s (fijo) | `1.0 / LOOP_HZ` |
| `_hover_loop` | Medido en tiempo real | `t0 - t_prev`, saturado 5–50 ms |

```python
dt_real = t0 - t_prev
dt_real = max(0.005, min(0.05, dt_real))
```

### Anti-windup
Implementado en `pid.py` mediante clamping del integrador:
```python
self._integral += error * dt
if self.i_limit is not None:
    self._integral = max(-self.i_limit, min(self.i_limit, self._integral))
```

---

## 3. Armado Obligatorio (Brushless)

**CRÍTICO — el firmware brushless no gira motores sin armado explícito.**

- Armar: `supervisor.send_arming_request(True)` (botón △ en PS4)
- Desarmar: `supervisor.send_arming_request(False)`
- El firmware puede desarmarse solo (volteo, timeout) — la app debe
  detectarlo y notificarlo

---

## 4. Compensación de Inclinación (Tilt Compensation)

**Obligatoria en TODO hover** — sin esto el dron se hunde al maniobrar.

```python
roll_r  = radians(roll_actual)   # de stabilizer.roll
pitch_r = radians(pitch_actual)  # de stabilizer.pitch
tilt    = 1.0 / max(cos(roll_r) * cos(pitch_r), 0.5)
thrust  = clamp(thrust * tilt, THRUST_MIN, THRUST_MAX)
```

Validada también en el modelo no lineal 6 DOF de la simulación.

---

## 5. Trim de Despegue y Aterrizaje

⚠️ Los trims son específicos de cada airframe — deben recalibrarse
experimentalmente con el CF 2.1 Brushless.

| Parámetro | CF 2.0 (referencia) | CF 2.1 BL |
|-----------|--------------------| ----------|
| ROLL_TRIM | -1.0 | Por calibrar |
| PITCH_TRIM | -0.5 | Por calibrar |
| ROLL_TRIM_LAND | -0.5 | Por calibrar |
| PITCH_TRIM_LAND | -0.75 | Por calibrar |

---

## 6. Aterrizaje Controlado (_land)

Rampa de descenso suave con polinomio quíntico. **Nunca corte seco salvo
paro de emergencia.**

```python
def quintic(q0, qf, T, t):
    if t <= 0: return q0
    if t >= T: return qf
    τ = t / T
    return q0 + (qf - q0) * (10*τ**3 - 15*τ**4 + 6*τ**5)
```

| Parámetro | Valor | Notas |
|-----------|-------|-------|
| BRAKE_THRESHOLD | 0.05 m | |
| LAND_THRESHOLD | 0.02 m | |
| BRAKE_THRUST | 30000 | ⚠️ Recalibrar para brushless (era proporcional a HOVER_THRUST=55000) |
| BRAKE_DURATION | 0.20 s | |

---

## 7. Control de Posición (Ejes X, Y)

Activo únicamente en **modo autónomo**, cuando la cámara detecta al dron.

⚠️ Ganancias heredadas del CF 2.0 — validar en banco con el brushless.

| Parámetro | Valor |
|-----------|-------|
| KP_VX = KP_VY | 5.50 |
| KI_VX = KI_VY | 0.12 |
| KD_VX = KD_VY | 0.81 |
| I_LIMIT_V | 5.0 |
| MAX_ANGLE | 15.0° |

---

## 8. Filtro EMA del Barómetro

La simulación con señal dinámica mostró diferencia marginal entre α=0.1
(11.2 cm) y α=0.5 (12.4 cm). **Decisión: mantener α=0.5** — un alpha muy
bajo introduce retardo que puede interactuar mal con KD en el hardware real.
Si en banco se observa ruido excesivo, probar rango 0.3–0.4.

---

## 9. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Ganancias PID CF 2.1 BL (KP=3885, KD=3100) | ⏳ Pendiente — validar en banco |
| HOVER_THRUST ~17500 | ⏳ Pendiente — validar en banco |
| Armado brushless (send_arming_request) | ⏳ Pendiente |
| Tilt compensation | ✅ Implementado (heredado) |
| Aterrizaje quíntico | ✅ Implementado (heredado) |
| Anti-windup | ✅ Implementado (heredado) |
| Trims CF 2.1 BL | ⏳ Pendiente — calibrar en vuelo |
