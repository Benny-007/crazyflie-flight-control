# Spec: Input PS4 — Crazyflie 2.0
**Versión:** 1.1  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Gestionar la lectura del mando PS4 y traducir sus entradas en comandos
de vuelo para el modo teleoperado del Crazyflie 2.0.

---

## 2. Hardware

| Parámetro | Valor |
|-----------|-------|
| Dispositivo | Control DualShock 4 (PS4) |
| Interfaz | USB |
| Librería | pygame |
| Sistema operativo | Linux (Ubuntu) |

---

## 3. Mapeo de Ejes — DualShock 4 en Linux (pygame/SDL)

| Índice | Control físico | Uso en app |
|--------|---------------|------------|
| axis 1 | Stick IZQ — eje Y | Altitud (`vz`) |
| axis 3 | Stick DER — eje X | Lateral (`vy_ref`) |
| axis 4 | Stick DER — eje Y | Frontal (`vx_ref`) |
| axis 2 | Gatillo L2 | ⚠️ NO usar — reposo = −1 |
| axis 5 | Gatillo R2 | ⚠️ NO usar — reposo = −1 |
| button 0 | Botón X | Armar / aterrizar |

---

## 4. Mapeo de Botones

| Botón | Acción |
|-------|--------|
| X (button 0) | Primer flanco → arma motores e inicia hover |
| X (button 0) | Segundo flanco (tras >3 s en hover) → aterrizaje controlado |

---

## 5. Parámetros de Control

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| PS4_MAX_VEL | 0.30 m/s | Velocidad máxima en XY |
| PS4_MAX_VZ | 0.75 m/s | Velocidad máxima vertical |
| PS4_DEADZONE | 0.08 | Zona muerta de joysticks |
| PS4_ALT_MIN | 0.15 m | Altitud mínima en modo PS4 |
| PS4_ALT_MAX | 3.00 m | Altitud máxima en modo PS4 |
| PS4_EXPO | 0.60 | Curva exponencial de respuesta |

---

## 6. Procesamiento de Entradas

### Zona muerta con renormalización
```python
def dead(v):
    if abs(v) < PS4_DEADZONE:
        return 0.0
    return (v - sign(v) * PS4_DEADZONE) / (1.0 - PS4_DEADZONE)
```

### Curva EXPO (obligatoria)
```python
def expo(v, e):
    return v * ((1 - e) + e * v * v)
```
Sin la curva EXPO el control es brusco y no coincide con la respuesta validada.

### Cálculo de setpoints — signos exactos
```python
# Altitud
raw_alt = axis(1)
vz      = -expo(dead(raw_alt), PS4_EXPO)
_z_ref  = clamp(_z_ref + vz * PS4_MAX_VZ * dt, PS4_ALT_MIN, PS4_ALT_MAX)

# Posición XY
raw_vx  = axis(4)
raw_vy  = axis(3)
_vx_ref = -expo(dead(raw_vx), PS4_EXPO) * PS4_MAX_VEL
_vy_ref =  expo(dead(raw_vy), PS4_EXPO) * PS4_MAX_VEL
```

⚠️ **Los signos de `_vx_ref`/`_vy_ref` están calibrados junto con los de
`pc`/`rc` en el hover loop. Invertir cualquiera mueve el dron al revés.**

### Conversión a ángulos de control
```python
scale = MAX_ANGLE / max(PS4_MAX_VEL, 0.01)
pc = clamp(-_vx_ref * scale, -MAX_ANGLE, MAX_ANGLE)
rc = clamp(-_vy_ref * scale, -MAX_ANGLE, MAX_ANGLE)
cf.commander.send_setpoint(ROLL_TRIM + rc, PITCH_TRIM + pc, 0, thrust)
```

---

## 7. Secuencia de Operación en Modo PS4

1. Conectar al Crazyflie y configurar LogConfig
2. Calibrar barómetro (200 muestras)
3. Esperar botón X — el bucle de espera cumple también el armado del firmware
4. Iniciar hover dinámico (dt medido en tiempo real)
5. Segundo flanco de X (tras >3 s en hover) → aterrizaje controlado

---

## 8. Restricciones

- En modo PS4 el lazo PID de posición XY **no está activo** — el operador
  controla la dirección manualmente con los joysticks
- El lazo PID de altitud sí permanece activo (altitude hold)
- El warm-up de ~25 ciclos al inicio ignora el estado inicial del botón X
  para evitar arranques accidentales
- Si el dron va en dirección contraria al stick, ajustar `CAM_SIGN_*` (modo
  auto) o el signo del eje correspondiente (modo PS4), nunca a ciegas

---

## 9. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Lectura de ejes correctos (1, 3, 4) | ✅ Implementado |
| Zona muerta con renormalización | ✅ Implementado |
| Curva EXPO (PS4_EXPO=0.60) | ✅ Implementado |
| Altitude hold en modo PS4 | ✅ Implementado |
| Armado por bucle de espera botón X | ✅ Implementado |
| Aterrizaje por segundo flanco botón X | ✅ Implementado |
