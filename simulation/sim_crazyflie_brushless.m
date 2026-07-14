%% =========================================================
%  sim_crazyflie_brushless.m  (v2 — corregido)
%  Simulación completa — Crazyflie 2.1 Brushless
%  Autor: Benny
%  Fecha: Junio 2026
%
%  Fuentes:
%  [R1] Bitcraze — Datasheet CF 2.1 Brushless (2024)
%  [R4] Förster — System ID Crazyflie 2.0, ETH Zurich (2015)
%  [R6] Mahony et al. — Modeling quadrotors, IEEE R&A Mag (2012)
%
%  v2: - Mapeo explícito PWM→Newtons
%      - Simulación discreta a 50 Hz con saturación de thrust
%      - Ruido de barómetro realista en todas las simulaciones
%      - EMA evaluado con señal dinámica (tracking + ruido)
% =========================================================
clear; clc; close all;
rng(7);  % semilla fija para reproducibilidad

%% =========================================================
%  SECCIÓN 1 — PARÁMETROS FÍSICOS [R1, R4]
% =========================================================
m   = 0.032;            % kg  [R1]
g   = 9.81;             % m/s²
T_max = 4*0.030*g;      % 1.177 N — 4 motores × 30 g [R1]
T_hover = m*g;          % 0.314 N

% --- Mapeo PWM → Newtons (aproximación lineal) ---
PWM_MAX = 65535;
kPWM = T_max / PWM_MAX;         % N por unidad PWM
HOVER_PWM = T_hover / kPWM;     % PWM de equilibrio ≈ 17480

% Saturaciones (mismas proporciones que el firmware)
THRUST_MIN_PWM = 8000;
THRUST_MAX_PWM = 60000;

% Matriz de inercia — escalada desde CF 2.0 [R4]
scale_I = 0.032/0.027;
Ixx = 16.57e-6*scale_I;  Iyy = 16.65e-6*scale_I;  Izz = 29.26e-6*scale_I;
J = diag([Ixx, Iyy, Izz]);

% Loop de control
LOOP_HZ = 50;  dt = 1/LOOP_HZ;
TARGET_ALT = 0.5;

% Ruido de barómetro (LPS22HH, tras BARO_GAIN)
BARO_NOISE_STD = 0.03;   % ~3 cm

% PID actuales (heredados del CF 2.0)
KP0 = 3750; KI0 = 50; KD0 = 5250; I_LIMIT = 5000;

fprintf('=== PARÁMETROS CF 2.1 BRUSHLESS ===\n');
fprintf('T_hover: %.3f N  →  HOVER_PWM teórico: %.0f\n', T_hover, HOVER_PWM);
fprintf('*** HALLAZGO: HOVER_THRUST=55000 (CF 2.0) NO aplica.\n');
fprintf('*** Para el brushless el equilibrio está en ~%.0f PWM.\n\n', HOVER_PWM);

%% =========================================================
%  SECCIÓN 2 — MODELO LINEAL (análisis formal, sin saturación)
% =========================================================
% El PID entrega PWM; la planta convierte PWM→N→aceleración:
% G(s) = kPWM / (m s²)
G = tf(kPWM, [m 0 0]);
C = pid(KP0, KI0, KD0);
[Gm, Pm] = margin(C*G);
fprintf('=== SIM 1: MODELO LINEAL ===\n');
fprintf('Margen de fase: %.1f°  (>45° = bien amortiguado)\n\n', Pm);

figure('Name','Fig 1 — Bode'); margin(C*G); grid on;
title('Bode Lazo Abierto — PID en unidades PWM, planta con kPWM');

%% =========================================================
%  Función de simulación discreta (la usamos en todo lo demás)
% =========================================================
sim_hover = @(KP,KI,KD,alpha,tsim,ref_fun) simulate_loop( ...
    KP,KI,KD,I_LIMIT,alpha,tsim,dt,m,g,kPWM,HOVER_PWM, ...
    THRUST_MIN_PWM,THRUST_MAX_PWM,BARO_NOISE_STD,ref_fun);

%% =========================================================
%  SECCIÓN 3 — HOVER REALISTA (discreto, saturado, con ruido)
% =========================================================
fprintf('=== SIM 2: HOVER DISCRETO 50 Hz ===\n');
t_sim = 12;
ref_step = @(t) TARGET_ALT*ones(size(t));
[t2, z2, ~] = sim_hover(KP0,KI0,KD0,0.5,t_sim,ref_step);

[peak,~] = max(z2);
OS = max(0,(peak-TARGET_ALT)/TARGET_ALT*100);
idx = find(abs(z2-TARGET_ALT) > 0.02*TARGET_ALT);
t_settle = t2(min(idx(end)+1, numel(t2)));
ss = t2 >= t_sim-4;
RMSE2 = sqrt(mean((z2(ss)-TARGET_ALT).^2));
fprintf('OS=%.1f%%  t_s=%.2f s  RMSE=%.1f cm\n\n', OS, t_settle, RMSE2*100);

figure('Name','Fig 2 — Hover discreto');
plot(t2,z2,'b','LineWidth',1.5); hold on;
yline(TARGET_ALT,'r--','LineWidth',1.5);
yline(TARGET_ALT*1.02,'g:'); yline(TARGET_ALT*0.98,'g:');
xlabel('Tiempo (s)'); ylabel('Altitud (m)'); grid on;
title(sprintf('Hover 50 Hz con saturación y ruido — OS=%.1f%%, RMSE=%.1f cm',OS,RMSE2*100));
legend('Altitud','Setpoint','Banda ±2%','Location','southeast');

%% =========================================================
%  SECCIÓN 4 — BARRIDO DE GANANCIAS (con el modelo realista)
% =========================================================
fprintf('=== SIM 3: BARRIDO KP × KD (realista) ===\n');
KP_r = linspace(500, 6000, 14);
KD_r = linspace(500, 9000, 14);
COST = nan(numel(KP_r), numel(KD_r));

for i = 1:numel(KP_r)
    for j = 1:numel(KD_r)
        [tb, zb] = sim_hover(KP_r(i),KI0,KD_r(j),0.5,10,ref_step);
        ssb = tb >= 6;
        rm  = sqrt(mean((zb(ssb)-TARGET_ALT).^2));
        pk  = max(zb);
        os  = max(0,(pk-TARGET_ALT)/TARGET_ALT);
        % costo = RMSE + penalización por overshoot (>25%)
        COST(i,j) = rm + 0.5*max(0, os-0.25);
    end
end

[~,imin] = min(COST(:));
[io,jo] = ind2sub(size(COST), imin);
KP_opt = KP_r(io); KD_opt = KD_r(jo);
fprintf('Óptimo realista: KP=%.0f  KD=%.0f  (costo=%.4f)\n\n', ...
        KP_opt, KD_opt, COST(io,jo));

figure('Name','Fig 3 — Barrido realista');
imagesc(KD_r, KP_r, COST*100); colorbar; colormap(parula);
xlabel('KD'); ylabel('KP');
title('Costo (RMSE cm + penal. overshoot) — CF 2.1 Brushless');
hold on; plot(KD_opt,KP_opt,'r*','MarkerSize',15,'LineWidth',2);
text(KD_opt,KP_opt,sprintf('  KP=%.0f, KD=%.0f',KP_opt,KD_opt), ...
     'Color','r','FontWeight','bold');

%% =========================================================
%  SECCIÓN 5 — EMA CON SEÑAL DINÁMICA
% =========================================================
fprintf('=== SIM 4: EMA (tracking dinámico) ===\n');
% Referencia que sube, mantiene y baja — simula vuelo real
ref_dyn = @(t) 0.5*(t>=1) - 0.25*(t>=6) ;  % 0→0.5 m en t=1, baja a 0.25 en t=6
alpha_r = 0.10:0.05:0.95;
RMSEa = zeros(size(alpha_r));
for k = 1:numel(alpha_r)
    [ta, za, ra] = sim_hover(KP0,KI0,KD0,alpha_r(k),10,ref_dyn);
    RMSEa(k) = sqrt(mean((za - ra).^2));
end
[~,ka] = min(RMSEa);
fprintf('Alpha óptimo (dinámico): %.2f   RMSE=%.1f cm\n', ...
        alpha_r(ka), RMSEa(ka)*100);
fprintf('Alpha=0.5:  RMSE=%.1f cm\n\n', RMSEa(alpha_r==0.5)*100);

figure('Name','Fig 4 — EMA dinámico');
plot(alpha_r, RMSEa*100, 'b-o','LineWidth',1.5,'MarkerFaceColor','b');
hold on; xline(0.5,'r--','Alpha actual');
xline(alpha_r(ka),'g--',sprintf('Óptimo %.2f',alpha_r(ka)));
xlabel('\alpha'); ylabel('RMSE de tracking (cm)'); grid on;
title('EMA — RMSE con señal dinámica (sube-mantiene-baja)');

%% =========================================================
%  SECCIÓN 6 — NO LINEAL 6 DOF (discreto, mismo PID)
% =========================================================
fprintf('=== SIM 5: NO LINEAL 6 DOF ===\n');
% Estados: [x y z vx vy vz phi theta psi p q r]
X = zeros(12,1);
X(7) = deg2rad(2);  X(8) = deg2rad(-1.5);  % perturbación inicial de actitud
N  = round(12/dt);
Z  = zeros(N,1); PH = Z; TH = Z; T_hist = Z;
int_z = 0; z_meas_f = 0; prev_err = 0;

for n = 1:N
    % medición con ruido + EMA (alpha 0.5)
    z_noisy = X(3) + BARO_NOISE_STD*randn;
    z_meas_f = 0.5*z_noisy + 0.5*z_meas_f;

    err = TARGET_ALT - z_meas_f;
    int_z = max(-I_LIMIT, min(I_LIMIT, int_z + err*dt));
    der = (err - prev_err)/dt;  prev_err = err;

    pwm = HOVER_PWM + KP0*err + KI0*int_z + KD0*der;
    pwm = max(THRUST_MIN_PWM, min(THRUST_MAX_PWM, pwm));
    T   = pwm * kPWM;

    % tilt compensation (igual que app.py)
    tilt = 1/max(cos(X(7))*cos(X(8)), 0.5);
    T = min(T*tilt, THRUST_MAX_PWM*kPWM);

    % dinámica traslacional [R6]
    ax = -(T/m)*sin(X(8));
    ay =  (T/m)*sin(X(7))*cos(X(8));
    az =  (T/m)*cos(X(7))*cos(X(8)) - g;

    % rotacional: pequeño amortiguamiento del firmware de actitud
    tau = -2e-6*X(10:12) - 5e-5*[X(7);X(8);0];
    dom = J\(tau - cross(X(10:12), J*X(10:12)));

    % integración de Euler
    X(1:3)   = X(1:3) + X(4:6)*dt;
    X(4:6)   = X(4:6) + [ax;ay;az]*dt;
    X(7:9)   = X(7:9) + X(10:12)*dt;
    X(10:12) = X(10:12) + dom*dt;
    X(3) = max(X(3), 0);  % suelo

    Z(n)=X(3); PH(n)=rad2deg(X(7)); TH(n)=rad2deg(X(8)); T_hist(n)=T;
end
t6 = (1:N)*dt;
ss6 = t6 >= 8;
RMSE6 = sqrt(mean((Z(ss6)-TARGET_ALT).^2));
fprintf('RMSE no lineal: %.1f cm\n', RMSE6*100);

figure('Name','Fig 5 — No lineal 6DOF','Position',[100 100 1000 600]);
subplot(2,2,1); plot(t6,Z,'r','LineWidth',1.5); hold on;
yline(TARGET_ALT,'k--'); xlabel('t (s)'); ylabel('z (m)');
title(sprintf('Altitud no lineal — RMSE=%.1f cm',RMSE6*100)); grid on;
subplot(2,2,2); plot(t6,PH,t6,TH,'LineWidth',1.2);
legend('\phi roll','\theta pitch'); xlabel('t (s)'); ylabel('°');
title('Actitud (converge por firmware)'); grid on;
subplot(2,2,3); plot(t6,T_hist/g*1000,'LineWidth',1.2);
yline(T_hover/g*1000,'k--','hover');
xlabel('t (s)'); ylabel('Thrust (gramos-fuerza)');
title('Thrust efectivo'); grid on;
subplot(2,2,4); plot(t6,(Z-TARGET_ALT)*100,'k','LineWidth',1.2);
yline(10,'r--'); yline(-10,'r--');
xlabel('t (s)'); ylabel('error (cm)'); title('Error de altitud'); grid on;

%% =========================================================
%  RESUMEN Y RECOMENDACIONES
% =========================================================
fprintf('\n========== RESUMEN v2 ==========\n');
fprintf('HOVER_PWM brushless: ~%.0f  (¡ya no 55000!)\n', HOVER_PWM);
fprintf('Margen de fase (lineal): %.1f°\n', Pm);
fprintf('Hover discreto: OS=%.1f%%, t_s=%.2f s, RMSE=%.1f cm\n', OS, t_settle, RMSE2*100);
fprintf('Ganancias recomendadas: KP=%.0f  KI=%.0f  KD=%.0f\n', KP_opt, KI0, KD_opt);
fprintf('Alpha EMA recomendado: %.2f\n', alpha_r(ka));
fprintf('No lineal 6DOF: RMSE=%.1f cm\n', RMSE6*100);
fprintf('================================\n');

%% =========================================================
%  FUNCIÓN — loop discreto 50 Hz con saturación y ruido
% =========================================================
function [t, z, ref_v] = simulate_loop(KP,KI,KD,I_LIM_arg,alpha, ...
    tsim,dt,m,g,kPWM,HOVER_PWM,PWM_MIN,PWM_MAX,noise_std,ref_fun)
    N = round(tsim/dt);
    t = (1:N)'*dt;
    z = zeros(N,1); ref_v = zeros(N,1);
    zi = 0; vz = 0; int_e = 0; prev_e = 0; z_f = 0;
    for n = 1:N
        r = ref_fun(t(n)); ref_v(n) = r;
        z_noisy = zi + noise_std*randn;
        z_f = alpha*z_noisy + (1-alpha)*z_f;
        e = r - z_f;
        int_e = max(-I_LIM_arg, min(I_LIM_arg, int_e + e*dt));
        de = (e - prev_e)/dt; prev_e = e;
        pwm = HOVER_PWM + KP*e + KI*int_e + KD*de;
        pwm = max(PWM_MIN, min(PWM_MAX, pwm));
        T = pwm*kPWM;
        az = T/m - g;
        vz = vz + az*dt;
        zi = max(0, zi + vz*dt);
        z(n) = zi;
    end
end
