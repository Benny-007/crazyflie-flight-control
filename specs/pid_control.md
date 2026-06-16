# Spec: Control PID — Crazyflie 2.0
**Versión:** 1.2  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Mantener altitud objetivo (eje Z) y posición (ejes X, Y) mediante lazos PID
implementados en Python. El control de altitud opera en ambos modos (autónomo
y PS4). El control de posición XY opera únicamente en modo autónomo.

---

## 2. Control de Altitud (Eje Z)

### Parámetros
| Parámetro | Valor | Notas |
|-----------|-------|-------|
| KP_ALT | 3750.0 | Validado: Pm ≈ 65°, OS ≈ 20% |
| KI_ALT | 50.0 | Anti-windup activo (I_LIMIT_ALT) |
| KD_ALT | 5250.0 | RMSE ≈ 7.1 cm en sim_hover |
| I_LIMIT_ALT | 5000.0 | Clamping del integrador en pid.py |
| HOVER_THRUST | 50000 | Thrust base de hover |
| THRUST_MIN | 20000 | Límite inferior de thrust |
| THRUST_MAX | 60000 | Límite superior de thrust |
| TARGET_ALTITUDE | 0.5 m | Altitud objetivo en modo autónomo |
| BARO_GAIN | 0.89 | Corrección de sobre-lectura del barómetro (efecto Venturi) |
| LOOP_HZ | 50 | Frecuencia del loop de control |
| RAMP_UP_TIME | 1.0 s | Duración de la rampa de despegue |
| RAMP_DOWN_TIME | 3.0 s | Duración de la rampa de aterrizaje |
| HOLD_TIME | 5.0 s | Tiempo de hover en modo autónomo antes de aterrizar |

### Manejo de dt

| Contexto | dt | Método |
|----------|----|--------|
| `_takeoff`, `_land`, `_open_loop_run` | 0.02 s (fijo) | `1.0 / LOOP_HZ` |
| `_hover_loop` | Medido en tiempo real | `t0 - t_prev`, saturado 5–50 ms |

```python
dt_real = t0 - t_prev
dt_real = max(0.005, min(0.05, dt_real))
```

### Comportamiento esperado
| Métrica | Valor objetivo |
|---------|---------------|
| RMSE en hover | < 10 cm |
| Overshoot en escalón 1 m | < 25% |
| Tiempo de establecimiento | < 3 s |

### Anti-windup
Implementado en `pid.py` mediante clamping del integrador:
```python
self._integral += error * dt
if self.i_limit is not None:
    self._integral = max(-self.i_limit, min(self.i_limit, self._integral))
```

---

## 3. Armado Obligatorio (Thrust Lock del Firmware)

**CRÍTICO — sin este paso el dron no arranca motores.**

Antes de cualquier thrust > 0, el firmware requiere recibir al menos 2 segundos
de `send_setpoint(0, 0, 0, 0)`. Este paso se ejecuta en `_autonomous_run`
tras completar la calibración del barómetro.

```python
# Armado: 2 s de thrust=0 antes de cualquier thrust>0
for _ in range(int(2.0 * LOOP_HZ)):
    cf.commander.send_setpoint(0, 0, 0, 0)
    time.sleep(1.0 / LOOP_HZ)
```

En modo PS4 el armado se cumple automáticamente por el bucle de espera
del botón X.

---

## 4. Compensación de Inclinación (Tilt Compensation)

**Obligatoria en TODO hover** — sin esto el dron se hunde al maniobrar.

Al inclinarse, el thrust vertical efectivo se reduce. La compensación corrige
esto antes de enviar el comando:

```python
roll_r  = radians(roll_actual)   # de stabilizer.roll
pitch_r = radians(pitch_actual)  # de stabilizer.pitch
tilt    = 1.0 / max(cos(roll_r) * cos(pitch_r), 0.5)
thrust  = clamp(thrust * tilt, THRUST_MIN, THRUST_MAX)
```

Requiere telemetría de `stabilizer.roll` y `stabilizer.pitch` activa
en todo momento (ver specs/gui.md — LogConfig).

---

## 5. Trim de Despegue y Aterrizaje

| Parámetro | Valor | Contexto |
|-----------|-------|---------|
| ROLL_TRIM | -1.0 | Despegue y hover |
| PITCH_TRIM | -0.5 | Despegue y hover |
| ROLL_TRIM_LAND | -0.5 | Aterrizaje/freno únicamente |
| PITCH_TRIM_LAND | -0.75 | Aterrizaje/freno únicamente |

---

## 6. Aterrizaje Controlado (_land)

Rampa de descenso suave con polinomio quíntico. **Nunca corte seco salvo
paro de emergencia.**

```python
# Polinomio quíntico
def quintic(q0, qf, T, t):
    if t <= 0: return q0
    if t >= T: return qf
    τ = t / T
    return q0 + (qf - q0) * (10*τ**3 - 15*τ**4 + 6*τ**5)
```

Fases del aterrizaje:
1. Descenso con rampa quíntica hasta `BRAKE_THRESHOLD`
2. Fase de freno: `BRAKE_THRUST` durante `BRAKE_DURATION` segundos
3. Corte final si `baro_alt <= LAND_THRESHOLD`

| Parámetro | Valor |
|-----------|-------|
| BRAKE_THRESHOLD | 0.05 m |
| LAND_THRESHOLD | 0.02 m |
| BRAKE_THRUST | 30000 |
| BRAKE_DURATION | 0.20 s |

---

## 7. Control de Posición (Ejes X, Y)

Activo únicamente en **modo autónomo**, cuando la cámara detecta al dron.

| Parámetro | Valor |
|-----------|-------|
| KP_VX = KP_VY | 5.50 |
| KI_VX = KI_VY | 0.12 |
| KD_VX = KD_VY | 0.81 |
| I_LIMIT_V | 5.0 |
| MAX_ANGLE | 15.0° |

---

## 8. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Ganancias PID altitud | ✅ Implementado |
| BARO_GAIN=0.89 | ✅ Implementado |
| Anti-windup con I_LIMIT_ALT=5000 | ✅ Implementado |
| dt fijo en takeoff/land | ✅ Implementado |
| dt real medido en hover_loop | ✅ Implementado |
| Armado obligatorio (2 s thrust=0) | ✅ Implementado |
| Tilt compensation en hover | ✅ Implementado |
| Aterrizaje controlado (rampa quíntica) | ✅ Implementado |
| PID posición XY | ✅ Implementado |
| Trim de despegue (ROLL=-1.0, PITCH=-0.5) | ✅ Implementado |
