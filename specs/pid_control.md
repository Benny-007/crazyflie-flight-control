# Spec: Control PID — Crazyflie 2.0
**Versión:** 1.0  
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
| KP_ALT | 3750 | Validado: Pm ≈ 65°, OS ≈ 20% |
| KI_ALT | 50 | Anti-windup activo |
| KD_ALT | 5250 | RMSE ≈ 7.1 cm en sim_hover |
| Frecuencia de loop | 50 Hz | |
| dt | Medido en tiempo real | `time.perf_counter()`, saturado 5–50 ms |

### Comportamiento esperado
| Métrica | Valor objetivo |
|---------|---------------|
| RMSE en hover | < 10 cm |
| Overshoot en escalón 1 m | < 25% |
| Tiempo de establecimiento | < 3 s |

### Anti-windup
- La integral se limita (clamping) para evitar acumulación durante el despegue
- Se activa desde el inicio del ramp de thrust

---

## 3. Control de Posición (Ejes X, Y)

- Activo únicamente en **modo autónomo**
- Se activa cuando el sistema de visión detecta al dron en cuadro
- Setpoint: centro del frame de la cámara cenital
- Salida: corrección de pitch y roll enviada al Crazyflie

---

## 4. Trim de Despegue

- Se aplican valores preestablecidos de roll y pitch calculados experimentalmente
- Objetivo: compensar deriva mecánica durante la fase de elevación inicial
- Se mantienen activos hasta que el dron es detectado por la cámara

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

| Mejora | Estado |
|--------|--------|
| Ganancias optimizadas (KP=3750, KI=50, KD=5250) | ⏳ Pendiente |
| dt medido en tiempo real | ⏳ Pendiente |
| Anti-windup durante ramp | ⏳ Pendiente |
