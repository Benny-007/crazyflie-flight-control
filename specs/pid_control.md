# Spec: Control PID — Crazyflie 2.0
**Versión:** 1.1  
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
| LOOP_HZ | 50 | Frecuencia del loop de control |

### Manejo de dt

El sistema usa dos comportamientos de dt según el contexto:

| Contexto | dt | Método |
|----------|----|--------|
| `_takeoff`, `_land`, `_open_loop_run` | 0.02 s (fijo) | `1.0 / LOOP_HZ` |
| `_hover_loop` | Medido en tiempo real | `t0 - t_prev`, saturado 5–50 ms |

El `dt_real` en hover se calcula así:
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
El thrust final se satura entre `THRUST_MIN` y `THRUST_MAX` pero esto
no retroalimenta al integrador.

---

## 3. Control de Posición (Ejes X, Y)

- Activo únicamente en **modo autónomo**
- Se activa cuando el sistema de visión detecta al dron en cuadro
- Setpoint: centro del frame de la cámara cenital
- Salida: corrección de pitch y roll enviada al Crazyflie

---

## 4. Trim de Despegue

| Parámetro | Valor | Contexto |
|-----------|-------|---------|
| ROLL_TRIM | 0.0 | Despegue |
| PITCH_TRIM | -1.25 | Despegue |
| ROLL_TRIM_LAND | -0.5 | Aterrizaje/freno únicamente |
| PITCH_TRIM_LAND | -0.75 | Aterrizaje/freno únicamente |

---

## 5. Validación

Ganancias de altitud validadas mediante simulación MATLAB con tres scripts:

| Script | Resultado |
|--------|-----------|
| `sim_lineal.m` | Margen de fase ≈ 65°, OS ≈ 20% |
| `sim_hover.m` | RMSE ≈ 7.1 cm |
| `sim_pid_sweep.m` | Punto óptimo en barrido KP×KD |

---

## 6. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Ganancias PID (KP=3750, KI=50, KD=5250) | ✅ Implementado |
| Anti-windup con I_LIMIT_ALT=5000 | ✅ Implementado |
| dt fijo en takeoff/land | ✅ Implementado |
| dt real medido en hover_loop | ✅ Implementado |
| Trim de despegue (PITCH_TRIM=-1.25) | ✅ Implementado |
