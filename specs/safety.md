# Spec: Seguridad y Paro de Emergencia — Crazyflie 2.0
**Versión:** 1.1  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Definir los protocolos de seguridad del sistema para proteger al operador
y a la aeronave durante el vuelo.

---

## 2. Aterrizaje Controlado (Protocolo Normal)

El aterrizaje estándar usa una rampa de descenso suave con polinomio quíntico.
**Nunca se cortan los motores de forma seca salvo en paro de emergencia.**

### Fases
1. Descenso con rampa quíntica desde altitud actual hasta `BRAKE_THRESHOLD`
2. Fase de freno: enviar `BRAKE_THRUST` con trims de aterrizaje durante
   `BRAKE_DURATION` segundos
3. Corte final cuando `baro_alt <= LAND_THRESHOLD`
4. Enviar `send_setpoint(0,0,0,0)` ~10 veces para detener motores

### Parámetros
| Parámetro | Valor |
|-----------|-------|
| BRAKE_THRESHOLD | 0.05 m |
| LAND_THRESHOLD | 0.02 m |
| BRAKE_THRUST | 30000 |
| BRAKE_DURATION | 0.20 s |
| RAMP_DOWN_TIME | 3.0 s |
| ROLL_TRIM_LAND | -0.5 |
| PITCH_TRIM_LAND | -0.75 |

---

## 3. Paro de Emergencia

### Activación
- Botón dedicado visible en todo momento en la GUI
- Disponible en ambos modos de operación (autónomo y PS4)
- No requiere confirmación — acción inmediata al presionar

### Efecto
- Corte instantáneo de potencia de los 4 motores al 0%
- El dron cae de forma inmediata
- El loop de control se detiene
- El CSV logger cierra y guarda el archivo correctamente

### Prioridad
- Tiene prioridad absoluta sobre cualquier otra instrucción del sistema
- Es la **única excepción** al protocolo de aterrizaje controlado
- Ninguna entrada del mando PS4 ni del modo autónomo puede bloquearlo

---

## 4. Restricciones

- El paro de emergencia es estrictamente **manual** — depende al 100% del
  criterio del operador
- No existe detección automática de fallos por software
- El aterrizaje controlado no puede interrumpirse con el botón X del PS4
  una vez iniciado — solo el paro de emergencia puede detenerlo

---

## 5. Recomendaciones de Operación

- El operador debe mantener visibilidad directa del dron en todo momento
- El operador debe tener acceso inmediato al botón de paro de emergencia
- Verificar conexión del Crazyradio PA antes de cada vuelo
- Nunca iniciar vuelo sin completar la calibración del barómetro

---

## 6. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Botón de paro de emergencia en GUI | ✅ Implementado |
| Corte inmediato de motores al 0% | ✅ Implementado |
| Cierre correcto del CSV al activarse | ✅ Implementado |
| Aterrizaje controlado con rampa quíntica | ✅ Implementado |
| Fase de freno antes del corte final | ✅ Implementado |
