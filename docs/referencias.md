# Referencias del Proyecto
**Proyecto:** Sistema de Vuelo Autónomo — Crazyflie 2.1 Brushless  
**Autor:** Benny  
**Última actualización:** Junio 2026  
**Nota:** Solo se incluyen fuentes verificadas, con acceso público comprobado.

---

## Formato de cita: APA 7a edición

---

## 1. Hardware y Plataforma

**[R1]** Bitcraze AB. (2024). *Crazyflie 2.1 Brushless — Product page*.  
Bitcraze. https://www.bitcraze.io/products/crazyflie-2-1-brushless/  
> Especificaciones oficiales del hardware: masa (32 g), motores 08028-10000KV,
> empuje máximo por motor (30 g), hélices BC55-35, ESCs integrados 1S 5A.
> **Usado en:** parámetros físicos del modelo de simulación.

**[R2]** Bitcraze AB. (2024). *Crazyflie 2.1 Brushless Datasheet — Rev 3*.  
Bitcraze. https://www.bitcraze.io/documentation/hardware/crazyflie_2_1_brushless/crazyflie_2_1_brushless-datasheet.pdf  
> Datasheet oficial con especificaciones eléctricas y mecánicas del CF 2.1 Brushless.
> **Usado en:** parámetros de hardware en SPEC.md y simulación MATLAB.

**[R3]** Bitcraze AB. (2024). *08028-10000KV Brushless Motor — Store page*.  
Bitcraze Store. https://store.bitcraze.io/products/crazyflie-2-1-brushless-08028-10000kv-brushless-motor  
> Especificaciones del motor: KV=10000, resistencia interna=520 mΩ,
> corriente pico=1.8 A, potencia máxima=7.2 W.
> **Usado en:** modelo de actuadores en simulación no lineal.

---

## 2. Identificación de Parámetros del Sistema

**[R4]** Förster, J. (2015). *System identification of the Crazyflie 2.0 nano
quadrocopter* [Bachelor's thesis, ETH Zurich].  
ETH Zurich. https://www.semanticscholar.org/paper/System-Identification-of-the-Crazyflie-2.0-Nano-F%C3%B6rster/7c614b5a930d38092b83459e63390c3721b408b5  
> Referencia fundamental para parámetros físicos del Crazyflie:
> matriz de inercia (Ixx, Iyy, Izz), constantes de thrust y torque,
> dinámica de motores. Base para el escalado de parámetros al CF 2.1 Brushless.
> **Usado en:** modelo lineal y no lineal en simulación MATLAB.

**[R5]** Giernacki, W., Skwierczyński, M., Witwicki, W., Wroński, P., &
Kozierski, P. (2017). Crazyflie 2.0 quadrotor as a platform for research
and education in robotics and control engineering. *22nd International
Conference on Methods and Models in Automation and Robotics (MMAR)*, 37–42.
IEEE. https://www.bitcraze.io/papers/giernacki_draft_crazyflie2.0.pdf  
> Revisión completa de la plataforma Crazyflie 2.0 como herramienta de
> investigación. Confirma parámetros físicos y arquitectura de control.
> **Usado en:** validación del modelo de la plataforma.

---

## 3. Modelado de Quadrotores

**[R6]** Mahony, R., Kumar, V., & Corke, P. (2012). Multirotor aerial vehicles:
Modeling, estimation, and control of quadrotor. *IEEE Robotics & Automation
Magazine*, 19(3), 20–32.  
https://ieeexplore.ieee.org/document/6289431  
> Referencia clásica para las ecuaciones de movimiento de quadrotores (6 DOF).
> Base teórica del modelo no lineal: traslación, rotación, fuerzas y torques.
> **Usado en:** ecuaciones del modelo no lineal en simulación MATLAB.

---

## 4. Librería de Control (cflib)

**[R7]** Bitcraze AB. (2024). *cflib — Crazyflie Python Library*.  
GitHub. https://github.com/bitcraze/crazyflie-lib-python  
> Librería oficial de Python para comunicación con el Crazyflie.
> Documentación de LogConfig, Commander, y supervisor.send_arming_request().
> **Usado en:** arquitectura de comunicación y telemetría en app.py.

**[R8]** Bitcraze AB. (2024). *PWM to Thrust documentation*.  
Bitcraze Firmware Docs. https://www.bitcraze.io/documentation/repository/crazyflie-firmware/master/functional-areas/pwm-to-thrust/  
> Documentación oficial de la relación entre PWM y thrust en el firmware.
> Referencia para la calibración del punto de hover.
> **Usado en:** cálculo de HOVER_THRUST en simulación y app.py.

---

## 5. Pendientes de Verificar

> Las siguientes fuentes están identificadas pero pendientes de acceso
> completo para confirmar datos exactos antes de incluirlas formalmente.

- Bauersfeld, L., et al. (2025). *How to Model Your Crazyflie Brushless*.
  arXiv:2603.05944. — Parámetros identificados experimentalmente del CF 2.1
  Brushless (matriz de inercia, dinámica de motores). Pendiente de acceso al PDF.

---

## Registro de Uso por Sección

| Referencia | Usado en |
|------------|---------|
| R1, R2, R3 | SPEC.md, specs/pid_control.md, simulación MATLAB |
| R4, R5 | Modelo lineal y no lineal MATLAB |
| R6 | Ecuaciones de movimiento modelo no lineal |
| R7 | app.py — comunicación cflib |
| R8 | Cálculo de HOVER_THRUST |
