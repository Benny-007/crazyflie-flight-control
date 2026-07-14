# Spec: Seguridad y Paro de Emergencia — Crazyflie 2.1 Brushless
**Versión:** 1.2  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Definir los protocolos de seguridad del sistema para proteger al operador
y a la aeronave durante el vuelo con el Crazyflie 2.1 Brushless.

---

## 2. Armado y Desarmado

El firmware brushless no gira motores hasta recibir una petición de armado
explícita — es una medida de seguridad del hardware.

| Acción | Comando | Efecto |
|--------|---------|--------|
| Armar | `supervisor.send_arming_request(True)` | Habilita motores, chip naranja "ARMADO" en GUI |
| Desarmar | `supervisor.send_arming_request(False)` | Corta motores de forma controlada |

### Desarmado automático del firmware
El firmware puede desarmarse solo en estos casos:
- El dron se voltea (detección de actitud)
- Timeout de inactividad
- La app lo detecta y notifica en el log de la GUI

---

## 3. Paro de Emergencia

### Activación
- Botón ○ del mando PS4
- Botón rojo dedicado en la GUI
- Tecla espacio en el teclado

### Efecto
- Envía `send_stop_setpoint()` — corta motores al instante
- Ejecuta `supervisor.send_arming_request(False)` — desarma el firmware
- El dron cae de forma inmediata
- El loop de control se detiene
- El CSV logger cierra y guarda el archivo correctamente

### Prioridad
- Tiene prioridad absoluta sobre cualquier otra instrucción del sistema
- Es la **única excepción** al protocolo de aterrizaje controlado
- Ninguna entrada del mando ni del modo autónomo puede bloquearlo

---

## 4. Aterrizaje Controlado (Protocolo Normal)

El aterrizaje estándar usa una rampa de descenso suave con polinomio quíntico.
**Nunca se cortan los motores de forma seca salvo en paro de emergencia.**

### Fases
1. Descenso con rampa quíntica desde altitud actual hasta `BRAKE_THRESHOLD`
2. Fase de freno: enviar `BRAKE_THRUST` con trims de aterrizaje durante
   `BRAKE_DURATION` segundos
3. Corte final cuando `baro_alt <= LAND_THRESHOLD`
4. Desarmar con `supervisor.send_arming_request(False)`

### Parámetros

⚠️ **Todos estos valores fueron calibrados para el CF 2.0 con
HOVER_THRUST=55000. Con el CF 2.1 Brushless (HOVER_THRUST≈17500, ver
specs/pid_control.md v1.3), deben recalibrarse — especialmente
BRAKE_THRUST, que era proporcional al hover anterior.**

| Parámetro | CF 2.0 (referencia) | CF 2.1 BL | Estado |
|-----------|---------------------|-----------|--------|
| BRAKE_THRESHOLD | 0.05 m | 0.05 m | Sin cambio esperado |
| LAND_THRESHOLD | 0.02 m | 0.02 m | Sin cambio esperado |
| BRAKE_THRUST | 30000 | **⚠️ Por recalcular** | 30000 es ~1.7× el nuevo hover — frenaría de más o empujaría hacia arriba en vez de amortiguar la caída |
| BRAKE_DURATION | 0.20 s | Por validar | Depende del nuevo BRAKE_THRUST |
| RAMP_DOWN_TIME | 3.0 s | 3.0 s | Punto de partida razonable |
| ROLL_TRIM_LAND | -0.5 | Por calibrar | Trim específico de airframe |
| PITCH_TRIM_LAND | -0.75 | Por calibrar | Trim específico de airframe |

**Regla práctica para BRAKE_THRUST en banco de pruebas:** empezar en un
valor cercano al nuevo HOVER_THRUST (~17500) y ajustar gradualmente hacia
arriba solo lo necesario para frenar la caída — nunca partir del valor
heredado del CF 2.0 sin escalarlo primero.

---

## 5. Comportamiento ante Desconexión del Mando

| Modo | Comportamiento |
|------|---------------|
| Modo altitud | La app mantiene la última altitud de referencia |
| Modo manual | La app corta el empuje |

---

## 6. Restricciones

- El paro de emergencia es la única forma de detener el dron de forma inmediata
- El aterrizaje controlado no puede interrumpirse una vez iniciado, salvo
  con el paro de emergencia
- El firmware puede desarmarse solo — la app debe manejar este evento

---

## 7. Recomendaciones de Operación

- Mantener visibilidad directa del dron en todo momento
- Tener acceso inmediato al botón de paro de emergencia durante el vuelo
- Verificar conexión del Crazyradio PA antes de cada vuelo
- No armar motores sin completar la calibración del barómetro
- Batería por debajo de 3.50 V → aterrizar inmediatamente

---

## 8. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Paro de emergencia (send_stop_setpoint) | ⏳ Pendiente |
| Armado/desarmado (send_arming_request) | ⏳ Pendiente |
| Detección de desarmado automático del firmware | ⏳ Pendiente |
| Aterrizaje controlado con rampa quíntica | ✅ Implementado |
| Cierre correcto del CSV al activarse | ✅ Implementado |
