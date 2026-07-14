# Spec: Barómetro — Crazyflie 2.1 Brushless
**Versión:** 1.2  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Gestionar la lectura, filtrado y calibración del barómetro integrado en el
Crazyflie 2.1 Brushless, que es el sensor principal disponible para el
control de altitud (mientras no se complete la configuración de Lighthouse
V2, que no provee altitud absoluta por sí solo en el eje Z).

---

## 2. Hardware

| Parámetro | Valor |
|-----------|-------|
| Sensor | **BMP388** (Bosch Sensortec, alta precisión) |
| Variable leída | `baro.asl` (altitud sobre nivel del mar) |
| Valor típico en Ciudad de México | ~2341 m |
| Interfaz | LogConfig vía cflib |
| Precisión relativa (datasheet) | ~8 Pa ≈ ±0.5 m en condiciones estáticas |

⚠️ **Corrección de versión anterior:** este documento listaba el LPS25H
(sensor del CF 2.0). El Crazyflie 2.1 Brushless usa el **BMP388**, montado
junto al IMU BMI088. La variable de firmware `baro.asl` es la misma en
ambos casos, pero el ruido y comportamiento del sensor pueden diferir.

---

## 3. Filtro EMA

| Parámetro | Valor | Justificación |
|-----------|-------|---------------|
| `_BARO_ALPHA` | 0.5 | Validado en CF 2.0 (LPS25H); mantenido como punto de partida para BMP388 |

⚠️ El valor de alpha=0.5 fue validado con el sensor del CF 2.0. La
simulación con el modelo del CF 2.1 Brushless (`simulation/sim_crazyflie_brushless.m`)
mostró diferencia marginal entre α=0.1 y α=0.5 con señal dinámica —
se mantiene 0.5 como decisión, pero debe confirmarse con ruido real
del BMP388 en banco de pruebas.

Implementado en `_log_cb`:
```python
_baro_filt = _BARO_ALPHA * rel + (1.0 - _BARO_ALPHA) * _baro_filt
```

---

## 4. Calibración Pre-vuelo

| Parámetro | Valor |
|-----------|-------|
| `_BARO_REF_N` | 200 muestras (~4 s a 50 Hz) |
| Timeout | 5 s en `_drone_run` y `_open_loop_run` |
| Referencia | Promedio de las 200 muestras → `_baro_ref` |
| Momento | Automático al iniciar cualquier modo de vuelo |

### Procedimiento
1. El dron debe estar estático en la superficie de despegue
2. El sistema toma 200 lecturas consecutivas de `baro.asl`
3. Se calcula el promedio como valor de referencia (`_baro_ref`)
4. Si no se completan en 5 s, el sistema cancela el vuelo
5. Toda lectura posterior se expresa como diferencia respecto a `_baro_ref`

---

## 5. BARO_GAIN

| Parámetro | Valor | Estado |
|-----------|-------|--------|
| BARO_GAIN | 0.89 | ⏳ Validado con LPS25H (CF 2.0) — **pendiente de revalidar con BMP388** |

Corrige la sobre-lectura del barómetro (efecto Venturi por el flujo de aire
de las hélices). El BMP388 puede tener una respuesta distinta a este efecto
por su ubicación y características — no asumir que 0.89 aplica igual hasta
confirmarlo en vuelo.

---

## 6. Restricciones

- No se utiliza `stateEstimate.z` — requiere Flow Deck o Z-ranger, hardware
  no disponible en este Crazyflie
- La deriva térmica del barómetro puede afectar lecturas en vuelos largos
- El filtro EMA introduce un retardo proporcional a α
- Lighthouse V2 (cuando esté configurado) no reemplaza al barómetro para
  altitud — Lighthouse típicamente da posición XYZ completa, pero el
  barómetro se mantiene como referencia/respaldo hasta confirmar
  la precisión vertical del sistema Lighthouse en este setup

---

## 7. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Filtro EMA (α=0.5) | ✅ Implementado (heredado de CF 2.0) |
| Calibración de 200 muestras pre-vuelo | ✅ Implementado |
| Timeout de 5 s si calibración falla | ✅ Implementado |
| BARO_GAIN revalidado para BMP388 | ⏳ Pendiente |
| Alpha revalidado con ruido real BMP388 | ⏳ Pendiente |
