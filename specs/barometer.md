# Spec: Barómetro — Crazyflie 2.0
**Versión:** 1.1  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Gestionar la lectura, filtrado y calibración del barómetro integrado en el
Crazyflie 2.0, que es el único sensor disponible para el control de altitud.

---

## 2. Hardware

| Parámetro | Valor |
|-----------|-------|
| Sensor | LPS25H (integrado en Crazyflie 2.0) |
| Variable leída | `baro.asl` (altitud sobre nivel del mar) |
| Valor típico en Ciudad de México | ~2341 m |
| Interfaz | LogConfig vía cflib |

---

## 3. Filtro EMA

| Parámetro | Valor | Justificación |
|-----------|-------|---------------|
| `_BARO_ALPHA` | 0.5 | Validado en sim_filtro_baro.m |
| RMSE sin filtro | 15.44 cm | Medido en simulación |
| RMSE con filtro | 7.28 cm | Mejora del 53% |

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

## 5. Restricciones

- No se utiliza `stateEstimate.z` — requiere Flow Deck o Z-ranger, hardware
  no disponible en este Crazyflie
- La deriva térmica del barómetro puede afectar lecturas en vuelos largos
- El filtro EMA introduce un retardo proporcional a α — valor de 0.5
  representa un balance validado entre suavizado y respuesta

---

## 6. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Filtro EMA (α=0.5) | ✅ Implementado |
| Calibración de 200 muestras pre-vuelo | ✅ Implementado |
| Timeout de 5 s si calibración falla | ✅ Implementado |
