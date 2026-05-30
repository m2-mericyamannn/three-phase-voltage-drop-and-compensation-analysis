clc;
clear;
close all;

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'Simulink'));

%% SIMULINK MODEL ADI
modelName = 'AG_gerilimDusumuKompanzasyon_Sim';

%% SISTEM PARAMETRELERI

P_kW = 15;
P = P_kW * 1000;

V_ll = 400;
V_ph = V_ll / sqrt(3);

f = 50;
w = 2*pi*f;

sim_stop_time = 0.6;

cosfi_ilk_values = [0.8 0.9];
cosfi_hedef = 1.0;

%% 100 m HAT PARAMETRELERI

L_km = 0.1;      % 100 m

R_km = 3.08;     % 6 mm^2
X_km = 0.08;

R_line = R_km * L_km;
X_line = X_km * L_km;
L_line = X_line / (2*pi*f);

%% SONUC DIZILERI

n = length(cosfi_ilk_values);

Q_load_values    = zeros(1,n);
Qc_values        = zeros(1,n);
Q_cap_values     = zeros(1,n);

I_ilk_values     = zeros(1,n);
I_son_values     = zeros(1,n);

C_yildiz_values  = zeros(1,n);
C_ucgen_values   = zeros(1,n);

Vsource_sim      = zeros(1,n);
Vload_sim        = zeros(1,n);
I_sim            = zeros(1,n);
DV_sim           = zeros(1,n);
DVp_sim          = zeros(1,n);

%% MODELI YUKLE

load_system(modelName);

%% HESAPLAMA + SIMULASYON

fprintf('\n--- IKI SENARYO KOMPANZASYONLU SIMULASYON HESABI ---\n\n');

for i = 1:n

    cosfi_ilk = cosfi_ilk_values(i);

    phi_ilk = acos(cosfi_ilk);

    Q_load = P * tan(phi_ilk);     % Enduktif yuk reaktif gucu [var]
    Qc = Q_load;                   % Hedef cosphi = 1 oldugu icin
    Q_cap = -Qc;                   % Kapasitif blok icin negatif [var]

    S_ilk = P / cosfi_ilk;
    S_son = P / cosfi_hedef;

    I_ilk = S_ilk / (sqrt(3) * V_ll);
    I_son = S_son / (sqrt(3) * V_ll);

    C_yildiz = Qc / (3 * w * V_ph^2);
    C_ucgen  = Qc / (3 * w * V_ll^2);

    %% Degerleri kaydet

    Q_load_values(i)   = Q_load;
    Qc_values(i)       = Qc;
    Q_cap_values(i)    = Q_cap;

    I_ilk_values(i)    = I_ilk;
    I_son_values(i)    = I_son;

    C_yildiz_values(i) = C_yildiz;
    C_ucgen_values(i)  = C_ucgen;

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

    %% SIMULASYONU CALISTIR

    simOut = sim(modelName, ...
        'StopTime', num2str(sim_stop_time), ...
        'ReturnWorkspaceOutputs', 'on');

    %% SIMULINK CIKTILARINI AL
    % Senin modelinde "out." olmadigi icin direkt isimler kullanildi.

    Vsource_sim(i) = get_last_value(simOut.get('Vsource_rms1'));
    Vload_sim(i)   = get_last_value(simOut.get('Vload_rms1'));
    I_sim(i)       = get_last_value(simOut.get('Iload_rms1'));

    DV_sim(i)  = Vsource_sim(i) - Vload_sim(i);
    DVp_sim(i) = (DV_sim(i) / Vsource_sim(i)) * 100;

    %% SONUCLARI YAZDIR

    fprintf('============================================================\n');
    fprintf('SENARYO %d: cos(phi) %.1f -> %.1f\n', ...
        i, cosfi_ilk, cosfi_hedef);
    fprintf('============================================================\n');

    fprintf('Aktif guc P                     = %.2f kW\n', P_kW);
    fprintf('Hat uzunlugu                    = 100 m\n');
    fprintf('Kablo kesiti                    = 6 mm^2\n');
    fprintf('V_ll                            = %.2f V\n', V_ll);

    fprintf('\nHat Parametreleri:\n');
    fprintf('R_line                          = %.6f ohm\n', R_line);
    fprintf('X_line                          = %.6f ohm\n', X_line);
    fprintf('L_line                          = %.8e H\n', L_line);

    fprintf('\nKompanzasyon Hesabi:\n');
    fprintf('Baslangic cos(phi)              = %.2f\n', cosfi_ilk);
    fprintf('Hedef cos(phi)                  = %.2f\n', cosfi_hedef);
    fprintf('Q_load                          = %.2f kVAr\n', Q_load/1000);
    fprintf('Gerekli Qc                      = %.2f kVAr\n', Qc/1000);
    fprintf('Simulink kapasitif Q_cap        = %.2f var\n', Q_cap);

    fprintf('\nTeorik Degerler:\n');
    fprintf('Kompanzasyon oncesi teorik I    = %.2f A\n', I_ilk);
    fprintf('Kompanzasyon sonrasi teorik I   = %.2f A\n', I_son);
    fprintf('Yildiz bagli C faz basina       = %.2f uF\n', C_yildiz*1e6);
    fprintf('Ucgen bagli C faz basina        = %.2f uF\n', C_ucgen*1e6);

    fprintf('\nKompanzasyonlu Simulasyon Sonuclari:\n');
    fprintf('Vsource_fn RMS                  = %.4f V\n', Vsource_sim(i));
    fprintf('Vload_fn RMS                    = %.4f V\n', Vload_sim(i));
    fprintf('Iload RMS                       = %.4f A\n', I_sim(i));
    fprintf('Gerilim dusumu                  = %.4f V\n', DV_sim(i));
    fprintf('Gerilim dusumu                  = %.4f %%\n\n', DVp_sim(i));

end

%% OZET TABLO

fprintf('\n====================== OZET TABLO ======================\n');
fprintf('Senaryo\tcos_ilk\tQc(kVAr)\tQ_cap(var)\tI_th_son(A)\tI_sim(A)\tVload(V)\tDV(V)\tDV(%%)\n');

for i = 1:n
    fprintf('%d\t%.1f\t%.2f\t\t%.2f\t\t%.2f\t\t%.3f\t\t%.3f\t\t%.3f\t%.3f\n', ...
        i, ...
        cosfi_ilk_values(i), ...
        Qc_values(i)/1000, ...
        Q_cap_values(i), ...
        I_son_values(i), ...
        I_sim(i), ...
        Vload_sim(i), ...
        DV_sim(i), ...
        DVp_sim(i));
end

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

    error('Timeseries kullan. To Workspace formatini kontrol et.');
end