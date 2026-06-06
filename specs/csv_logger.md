# Spec: CSV Logger — Crazyflie 2.0
**Versión:** 1.0  
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
# Crazyflie Flight Log
# Fecha: YYYY-MM-DD HH:MM:SS
# Modo: Autónomo / PS4
```

### Columnas
| Columna | Unidad | Descripción |
|---------|--------|-------------|
| timestamp | s | Tiempo transcurrido desde inicio de vuelo |
| baro_raw | m | Lectura cruda del barómetro |
| baro_filtered | m | Lectura filtrada con EMA |
| alt_setpoint | m | Altura deseada |
| motor_m1 | % | Potencia motor 1 |
| motor_m2 | % | Potencia motor 2 |
| motor_m3 | % | Potencia motor 3 |
| motor_m4 | % | Potencia motor 4 |

---

## 4. Restricciones

- No se utiliza formato `.mat`
- El archivo se genera localmente en la computadora de la estación terrena
- Si ocurre un paro de emergencia, el archivo se cierra y guarda correctamente

---

## 5. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Auto-guardado al iniciar vuelo | ✅ Implementado |
| Metadata en encabezado | ✅ Implementado |
| Botón de exportación manual en topbar | ✅ Implementado |
