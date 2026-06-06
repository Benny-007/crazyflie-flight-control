# Spec: Barómetro — Crazyflie 2.0
**Versión:** 1.0  
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

La lectura cruda del barómetro presenta ruido significativo. Se aplica un
filtro de media móvil exponencial (EMA) antes de alimentar el PID.

| Parámetro | Valor | Justificación |
|-----------|-------|---------------|
| Alpha (α) | 0.5 | Validado en sim_filtro_baro.m |
| RMSE sin filtro | 15.44 cm | Medido en simulación |
| RMSE con filtro | 7.28 cm | Mejora del 53% |

### Fórmula
```
baro_filtered = α * baro_raw + (1 - α) * baro_filtered_prev
```

---

## 4. Calibración Pre-vuelo

Antes de armar los motores, el sistema realiza una calibración obligatoria
para establecer la referencia de altitud relativa (nivel del suelo = 0 m).

| Parámetro | Valor |
|-----------|-------|
| Número de muestras | 50 |
| Referencia | Promedio de las 50 muestras |
| Momento | Antes de activar cualquier modo de vuelo |

### Procedimiento
1. El dron debe estar estático en la superficie de despegue
2. El sistema toma 50 lecturas consecutivas del barómetro
3. Se calcula el promedio como valor de referencia cero
4. Toda lectura posterior se expresa como diferencia respecto a ese valor

---

## 5. Restricciones

- No se utiliza `stateEstimate.z` — requiere Flow Deck o Z-ranger, hardware
  no disponible en este Crazyflie
- La deriva térmica del barómetro puede afectar lecturas en vuelos largos
- El filtro EMA introduce un retardo proporcional a α — valor de 0.5
  representa un balance validado entre suavizado y respuesta

---

## 6. Estado de Implementación

| Mejora | Estado |
|--------|--------|
| Filtro EMA (α=0.5) | ⏳ Pendiente |
| Calibración de 50 muestras pre-vuelo | ⏳ Pendiente |
