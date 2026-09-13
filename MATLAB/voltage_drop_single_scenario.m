clc;
clear;
close all;

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'SIMULINK'));

%% =========================
% SIMULINK MODEL ADI
%% =========================
modelName = 'three_phase_voltage_drop';

%% =========================
% TEK SENARYO SECIMI
%% =========================
selected_cable_index = 2;     % 1: 4 mm^2, 2: 6 mm^2, 3: 10 mm^2
selected_line_length_m = 80;  % 20, 40, 60, 80, 100
selected_power_factor = 0.8;  % 0.8, 0.9, 1.0

%% =========================
% SISTEM PARAMETRELERI
%% =========================
V_ll   = 400;                 % Hatlar arasi gerilim RMS [V]
V_ph   = V_ll / sqrt(3);      % Faz-notr RMS [V]
P_load = 15000;               % Toplam 3 faz aktif guc [W]
f      = 50;                  % Frekans [Hz]

sim_stop_time = 0.6;          % Simulasyon suresi [s]

%% =========================
% KABLO VERILERI
%% =========================
kablo(1).kesit = '4 mm^2';
kablo(1).R = 4.61;            % ohm/km
kablo(1).X = 0.08;            % ohm/km

kablo(2).kesit = '6 mm^2';
kablo(2).R = 3.08;
kablo(2).X = 0.08;

kablo(3).kesit = '10 mm^2';
kablo(3).R = 1.83;
kablo(3).X = 0.08;

%% =========================
% SECILEN SENARYO PARAMETRELERI
%% =========================
cosphi = selected_power_factor;
sinphi = sqrt(1 - cosphi^2);
phi = acos(cosphi);

Q_load = P_load * tan(phi);       % toplam 3 faz reaktif guc [var]

line_length_m  = selected_line_length_m;
line_length_km = line_length_m / 1000;

R_km = kablo(selected_cable_index).R;
X_km = kablo(selected_cable_index).X;

R_line = R_km * line_length_km;   % toplam hat direnci [ohm]
X_line = X_km * line_length_km;   % toplam hat reaktansi [ohm]
L_line = X_line / (2*pi*f);       % toplam hat enduktansi [H]

%% =========================
% SIMULINK WORKSPACE DEGISKENLERI
%% =========================
assignin('base','V_ll',V_ll);
assignin('base','f',f);
assignin('base','P_load',P_load);
assignin('base','Q_load',Q_load);
assignin('base','R_line',R_line);
assignin('base','L_line',L_line);
assignin('base','sim_stop_time',sim_stop_time);

%% =========================
% MODELI YUKLE VE CALISTIR
%% =========================
load_system(modelName);

simOut = sim(modelName, ...
    'StopTime', num2str(sim_stop_time), ...
    'ReturnWorkspaceOutputs', 'on');

%% =========================
% SIMULINK CIKTILARINI AL
%% =========================
Vsrc_temp = simOut.get('Vsource_rms');
Vld_temp  = simOut.get('Vload_rms');
I_temp    = simOut.get('Iload_rms');

Vsource_sim = get_last_value(Vsrc_temp);
Vload_sim   = get_last_value(Vld_temp);
I_sim       = get_last_value(I_temp);

%% =========================
% SIMULASYON SONUCLARI
%% =========================
DV_sim  = Vsource_sim - Vload_sim;
DVp_sim = (DV_sim / Vsource_sim) * 100;

%% =========================
% TEORIK TEK FAZ HESAP
%% =========================
I_theory = P_load / (sqrt(3) * V_ll * cosphi);

DV_theory = I_theory * (R_km*cosphi + X_km*sinphi) * line_length_km;

Vload_theory = V_ph - DV_theory;
DVp_theory   = (DV_theory / V_ph) * 100;

%% =========================
% HATA HESABI
%% =========================
if abs(DV_theory) > 1e-12
    error_pct = abs(DV_sim - DV_theory) / abs(DV_theory) * 100;
else
    error_pct = 0;
end

%% =========================
% SONUCLARI YAZDIR
%% =========================
fprintf('\n============================================================\n');
fprintf('TEK SENARYO SONUCU\n');
fprintf('============================================================\n');
fprintf('Kablo kesiti        = %s\n', kablo(selected_cable_index).kesit);
fprintf('Hat uzunlugu        = %d m\n', line_length_m);
fprintf('cos(phi)            = %.2f\n', cosphi);
fprintf('Q_load              = %.2f var\n', Q_load);
fprintf('------------------------------------------------------------\n');

fprintf('Simulink Parametreleri:\n');
fprintf('  R_line            = %.6f ohm\n', R_line);
fprintf('  X_line            = %.6f ohm\n', X_line);
fprintf('  L_line            = %.8e H\n', L_line);

fprintf('\nSimulasyon Sonuclari:\n');
fprintf('  Vkaynak_fn RMS    = %.4f V\n', Vsource_sim);
fprintf('  Vyuk_fn RMS       = %.4f V\n', Vload_sim);
fprintf('  Cekilen akim RMS  = %.4f A\n', I_sim);
fprintf('  Teorik akim RMS   = %.4f A\n', I_theory);
fprintf('  DeltaV_sim        = %.4f V\n', DV_sim);
fprintf('  DeltaV_sim        = %.4f %%\n', DVp_sim);

fprintf('\nTeorik Sonuclar:\n');
fprintf('  DeltaV_theory     = %.4f V\n', DV_theory);
fprintf('  Vload_theory_fn   = %.4f V\n', Vload_theory);
fprintf('  DeltaV_theory     = %.4f %%\n', DVp_theory);
fprintf('  Hata              = %.4f %%\n', error_pct);
fprintf('============================================================\n');

%% =========================
% YARDIMCI FONKSIYON
%% =========================
function val = get_last_value(x)

    T = 1/50; % 1 periyot = 0.02 s

    if isa(x, 'timeseries')
        t = x.Time;
        data = x.Data;

        t_end = t(end);
        idx = t >= (t_end - T);

        data_seg = data(idx);

        val = sqrt(mean(data_seg.^2));
        return;
    end

    if isnumeric(x)
        val = x(end);
        return;
    end

    error('Timeseries kullan. To Workspace formatini degistir.');
end
