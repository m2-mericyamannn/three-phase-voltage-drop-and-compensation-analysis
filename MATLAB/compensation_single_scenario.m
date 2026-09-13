clc;
clear;
close all;

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'SIMULINK'));

%% SIMULINK MODEL ADI
modelName = 'three_phase_voltage_drop_with_compensation';

%% SENARYO SECIMI
% 1 → cosφ 0.8
% 2 → cosφ 0.9

scenario_number = 1;

%% SISTEM PARAMETRELERI

P_kW = 15;
V_ll = 400;
V_ph = V_ll / sqrt(3);
f = 50;
w = 2*pi*f;

sim_stop_time = 0.6;

%% 100 m HAT PARAMETRELERI

L_km = 0.1;       % 100 m

R_km = 3.08;     % 6 mm^2
X_km = 0.08;

R_line = R_km * L_km;
X_line = X_km * L_km;
L_line = X_line / (2*pi*f);

%% cosphi secimi

switch scenario_number
    case 1
        cosfi_ilk = 0.8;
    case 2
        cosfi_ilk = 0.9;
    otherwise
        error('Gecersiz senaryo numarasi.');
end

cosfi_hedef = 1;

%% KOMPANZASYON HESABI

P = P_kW * 1000;

phi_ilk = acos(cosfi_ilk);

Q_load = P * tan(phi_ilk);     % Yukun enduktif reaktif gucu
Qc = Q_load;                   % Hedef cosfi = 1 oldugu icin
Q_cap = -Qc;                   % Kapasitif Q negatif girilir

I_ilk_teorik = P / (sqrt(3)*V_ll*cosfi_ilk);
I_son_teorik = P / (sqrt(3)*V_ll*cosfi_hedef);

C_ucgen  = Qc / (3*w*V_ll^2);
C_yildiz = Qc / (3*w*V_ph^2);

%% SIMULINK'E GONDER

assignin('base','P_load',P);
assignin('base','Q_load',Q_load);
assignin('base','Q_cap',Q_cap);

assignin('base','R_line',R_line);
assignin('base','L_line',L_line);

assignin('base','V_ll',V_ll);
assignin('base','V_ph',V_ph);
assignin('base','f',f);
assignin('base','sim_stop_time',sim_stop_time);

%% MODELI CALISTIR - SADECE KOMPANZASYONLU

load_system(modelName);

simOut_comp = sim(modelName, ...
    'StopTime', num2str(sim_stop_time), ...
    'ReturnWorkspaceOutputs', 'on');

%% SIMULINK CIKTILARINI AL

Vsource_comp = get_last_value(simOut_comp.get('Vsource_rms'));
Vload_comp   = get_last_value(simOut_comp.get('Vload_rms'));
I_comp       = get_last_value(simOut_comp.get('Iload_rms'));
DV_comp  = Vsource_comp - Vload_comp;
DVp_comp = (DV_comp / Vsource_comp) * 100;

%% SONUCLAR

fprintf('\n============================================================\n');
fprintf('100 m HAT - KOMPANZASYONLU SIMULASYON SONUCU\n');
fprintf('============================================================\n');

fprintf('Senaryo                         = %d\n', scenario_number);
fprintf('Kablo kesiti                    = 6 mm^2\n');
fprintf('Hat uzunlugu                    = 100 m\n');
fprintf('cos(phi) ilk                    = %.2f\n', cosfi_ilk);
fprintf('cos(phi) hedef                  = %.2f\n', cosfi_hedef);

fprintf('\nHat Parametreleri:\n');
fprintf('R_line                          = %.6f ohm\n', R_line);
fprintf('X_line                          = %.6f ohm\n', X_line);
fprintf('L_line                          = %.8e H\n', L_line);

fprintf('\nKompanzasyon Hesabi:\n');
fprintf('P_load                          = %.2f kW\n', P_kW);
fprintf('Q_load                          = %.2f kVAr\n', Q_load/1000);
fprintf('Gerekli Qc                      = %.2f kVAr\n', Qc/1000);
fprintf('Simulink capacitor Q_cap        = %.2f var\n', Q_cap);

fprintf('\nTeorik Degerler:\n');
fprintf('Kompanzasyon oncesi teorik I    = %.2f A\n', I_ilk_teorik);
fprintf('Kompanzasyon sonrasi teorik I   = %.2f A\n', I_son_teorik);
fprintf('Ucgen bagli C faz basina        = %.2f uF\n', C_ucgen*1e6);
fprintf('Yildiz bagli C faz basina       = %.2f uF\n', C_yildiz*1e6);

fprintf('\nSimulasyon Sonuclari - Kompanzasyonlu:\n');
fprintf('Vsource_fn                      = %.4f V\n', Vsource_comp);
fprintf('Vload_fn                        = %.4f V\n', Vload_comp);
fprintf('Iload                           = %.4f A\n', I_comp);
fprintf('Gerilim dusumu                  = %.4f V\n', DV_comp);
fprintf('Gerilim dusumu                  = %.4f %%\n', DVp_comp);

fprintf('\n============================================================\n');

%% YARDIMCI FONKSIYON
function val = get_last_value(x)

    T = 1/50;

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
