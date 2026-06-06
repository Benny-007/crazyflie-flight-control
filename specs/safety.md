# Spec: Seguridad y Paro de Emergencia — Crazyflie 2.0
**Versión:** 1.0  
**Estado:** Borrador  
**Autor:** Benny  
**Última actualización:** Junio 2026

---

## 1. Propósito

Definir el protocolo de seguridad del sistema para proteger al operador
y a la aeronave ante situaciones de peligro durante el vuelo.

---

## 2. Paro de Emergencia

### Activación
- Botón dedicado visible en todo momento en la pestaña principal de la GUI
- Disponible en ambos modos de operación (autónomo y PS4)
- No requiere confirmación — acción inmediata al presionar

### Efecto
- Corte instantáneo de potencia de los 4 motores al 0%
- El dron cae de forma inmediata
- El loop de control se detiene

### Prioridad
- El paro de emergencia tiene prioridad sobre cualquier otra instrucción
  del sistema, incluyendo entradas del mando PS4 y comandos del modo autónomo

---

## 3. Restricciones

- El protocolo es estrictamente **manual** — depende al 100% del criterio
  del operador
- No existe paro de emergencia automático por software (sin detección
  automática de fallos)
- El CSV logger cierra y guarda el archivo correctamente al activarse
  el paro de emergencia

---

## 4. Recomendaciones de Operación

- El operador debe mantener visibilidad directa del dron en todo momento
- El operador debe tener acceso inmediato al botón de paro de emergencia
  durante cualquier vuelo
- Antes de cada vuelo verificar la conexión del Crazyradio PA

---

## 5. Estado de Implementación

| Componente | Estado |
|------------|--------|
| Botón de paro de emergencia en GUI | ✅ Implementado |
| Corte inmediato de motores al 0% | ✅ Implementado |
| Cierre correcto del CSV al activarse | ✅ Implementado |
