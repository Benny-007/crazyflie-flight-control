# Spec: CSV Logger — Crazyflie 2.1 Brushless
**Versión:** 1.1  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Registrar automáticamente los datos de telemetría durante el vuelo en un
archivo CSV para análisis posterior.

---

## 2. Funcionamiento

- El registro inicia automáticamente al comenzar cualquier modo de vuelo
- El archivo se guarda en la misma carpeta que `app.py`
- El usuario puede exportar manualmente el archivo desde el botón en la topbar

---

## 3. Formato del Archivo

### Nombre
```
vuelo_YYYYMMDD_HHMMSS.csv
```

### Encabezado de Metadata
```
# Crazyflie Flight Log — CF 2.1 Brushless
# Fecha: YYYY-MM-DD HH:MM:SS
# Modo: Autónomo / PS4 (MANUAL / ALTITUD)
```

### Columnas

⚠️ **Actualizado respecto a v1.0** — se agregan `vbat` y `thrust_total`
para respaldar las nuevas gráficas de batería y thrust del panel de estado
(ver specs/gui.md v1.3 §5).

| Columna | Unidad | Descripción |
|---------|--------|-------------|
| timestamp | s | Tiempo transcurrido desde inicio de vuelo |
| baro_raw | m | Lectura cruda del barómetro (BMP388) |
| baro_filtered | m | Lectura filtrada con EMA |
| alt_setpoint | m | Altura deseada |
| motor_m1 | % | Potencia motor 1 |
| motor_m2 | % | Potencia motor 2 |
| motor_m3 | % | Potencia motor 3 |
| motor_m4 | % | Potencia motor 4 |
| thrust_total | PWM | Thrust total enviado (para gráfica de thrust en GUI) |
| vbat | V | Voltaje de batería (`pm.vbat`) |
| roll | ° | `stabilizer.roll` |
| pitch | ° | `stabilizer.pitch` |
| armed | bool | Estado de armado del firmware |

---

## 4. Restricciones

- No se utiliza formato `.mat`
- El archivo se genera localmente en la computadora de la estación terrena
- Si ocurre un paro de emergencia, el archivo se cierra y guarda correctamente
- Las columnas `thrust_total` y `vbat` requieren que `specs/gui.md` §9
  (LogConfig `lc_bat`) esté implementado — actualmente pendiente

---

## 5. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Auto-guardado al iniciar vuelo | ✅ Implementado |
| Metadata en encabezado | ✅ Implementado |
| Botón de exportación manual en topbar | ✅ Implementado |
| Columnas thrust_total y vbat | ⏳ Pendiente — depende de LogConfig lc_bat |
| Columna armed | ⏳ Pendiente |
