# Spec: Input PS4 — Crazyflie 2.1 Brushless
**Versión:** 1.2  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Gestionar la lectura del mando PS4 y traducir sus entradas en comandos
de vuelo para el modo teleoperado del Crazyflie 2.1 Brushless.

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

---

## 4. Mapeo de Botones

| Botón | Acción |
|-------|--------|
| △ Triángulo | Primera pulsación → ARMA motores |
| △ Triángulo | Segunda pulsación → inicia aterrizaje controlado (desarme automático al finalizar) || ○ Círculo | Paro de emergencia — `send_stop_setpoint()` + desarmar |

### Comportamiento del armado (△)
- El firmware brushless **no gira motores hasta que se arma** — medida de
  seguridad del hardware
- La app manda `supervisor.send_arming_request(True)` para armar
- Al armar: chip naranja "ARMADO" en GUI, vibra el control
- El firmware puede desarmarse solo si el dron se voltea o por timeout —
  la app lo detecta y lo notifica en el log

⚠️ **Corrección de versión anterior:** la segunda pulsación de △ NO desarma
directamente. Desarmar en pleno vuelo cortaría motores en el aire —
el dron caería sin control. La segunda pulsación **inicia el aterrizaje
controlado** (rampa quíntica, ver specs/safety.md §4); el desarme
(`send_arming_request(False)`) ocurre automáticamente **al final** del
aterrizaje, cuando `baro_alt <= LAND_THRESHOLD`.
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

⚠️ **Los signos están calibrados juntos. Invertir cualquiera mueve el dron
al revés. Si ocurre, ajustar el signo del eje correspondiente, nunca a ciegas.**

---

## 7. Secuencia de Operación

1. Conectar al Crazyflie y configurar LogConfig
2. Calibrar barómetro (200 muestras)
3. Presionar △ para armar motores
4. Volar con joysticks
5. Presionar △ nuevamente para iniciar aterrizaje controlado (el desarme ocurre automáticamente al completarse)6. ○ en cualquier momento para paro de emergencia

---

## 8. Restricciones

- El dron brushless **no responde a thrust hasta estar armado**
- El firmware puede desarmarse automáticamente por seguridad (volteo, timeout)
- El warm-up de ~25 ciclos al inicio ignora el estado inicial de los botones
  para evitar armados accidentales
- Si el dron va en dirección contraria al stick, ajustar el signo del eje
  correspondiente, nunca a ciegas

---

## 9. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Lectura de ejes correctos (1, 3, 4) | ✅ Implementado |
| Zona muerta con renormalización | ✅ Implementado |
| Curva EXPO (PS4_EXPO=0.60) | ✅ Implementado |
| Altitude hold en modo PS4 | ✅ Implementado |
| Armado con △ (send_arming_request) | ⏳ Pendiente |
| Paro de emergencia con ○ | ⏳ Pendiente |
