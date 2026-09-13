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
% SISTEM PARAMETRELERI
%% =========================
V_ll   = 400;                 % Hatlar arasi gerilim RMS [V]
V_ph   = V_ll / sqrt(3);      % Faz-notr gerilimi RMS [V]
P_load = 15000;               % Toplam 3 faz aktif guc [W]
f      = 50;                  % Frekans [Hz]

sim_stop_time = 0.6;          % Simulasyon suresi [s]

%% Hat uzunluklari
L_m  = [20 40 60 80 100];
L_km = L_m / 1000;

%% cos(phi) degerleri
cosphi_values = [0.8 0.9 1.0];

%% Kablo verileri
kablo(1).kesit = '4 mm^2';
kablo(1).R = 4.61;       % ohm/km
kablo(1).X = 0.08;       % ohm/km

kablo(2).kesit = '6 mm^2';
kablo(2).R = 3.08;
kablo(2).X = 0.08;

kablo(3).kesit = '10 mm^2';
kablo(3).R = 1.83;
kablo(3).X = 0.08;

%% Boyutlar
numKablo = length(kablo);
numL     = length(L_km);
numCos   = length(cosphi_values);

%% Sonuc dizileri

% Simulinkten gelenler
Vsource_sim = zeros(numKablo, numL, numCos);
Vload_sim   = zeros(numKablo, numL, numCos);
I_sim       = zeros(numKablo, numL, numCos);
DV_sim      = zeros(numKablo, numL, numCos);
DVp_sim     = zeros(numKablo, numL, numCos);

% Teorik hesaplar
I_theory     = zeros(numKablo, numL, numCos);
DV_theory    = zeros(numKablo, numL, numCos);
DVp_theory   = zeros(numKablo, numL, numCos);
Vload_theory = zeros(numKablo, numL, numCos);

% Ek bilgi
Q_values    = zeros(1, numCos);
sinphi_vals = zeros(1, numCos);
error_pct   = zeros(numKablo, numL, numCos);

%% Modeli yukle
load_system(modelName);

%% =========================
% ANA HESAPLAMA + SIMULASYON DONGUSU
%% =========================
for c = 1:numCos

    cosphi = cosphi_values(c);
    sinphi = sqrt(1 - cosphi^2);
    sinphi_vals(c) = sinphi;

    phi = acos(cosphi);

    % Toplam 3 faz reaktif guc
    Q_load = P_load * tan(phi);
    Q_values(c) = Q_load;

    % Teorik yuk akimi
    I_calc = P_load / (sqrt(3) * V_ll * cosphi);

    for k = 1:numKablo

        R_km = kablo(k).R;
        X_km = kablo(k).X;

        for i = 1:numL

            line_length_m  = L_m(i);
            line_length_km = L_km(i);

            %% Hat parametreleri
            R_line = R_km * line_length_km;
            X_line = X_km * line_length_km;
            L_line = X_line / (2*pi*f);

            %% Simulink workspace degiskenleri
            assignin('base','V_ll',V_ll);
            assignin('base','f',f);
            assignin('base','P_load',P_load);
            assignin('base','Q_load',Q_load);
            assignin('base','R_line',R_line);
            assignin('base','L_line',L_line);
            assignin('base','sim_stop_time',sim_stop_time);

            %% Simulasyonu calistir
            simOut = sim(modelName, ...
                'StopTime', num2str(sim_stop_time), ...
                'ReturnWorkspaceOutputs', 'on');

            %% Simulink ciktilarini al
            Vsrc_temp = simOut.get('Vsource_rms');
            Vld_temp  = simOut.get('Vload_rms');
            I_temp    = simOut.get('Iload_rms');

            Vsource_sim(k,i,c) = get_last_value(Vsrc_temp);
            Vload_sim(k,i,c)   = get_last_value(Vld_temp);
            I_sim(k,i,c)       = get_last_value(I_temp);

            %% Simulasyon faz gerilim dusumu
            DV_sim(k,i,c)  = Vsource_sim(k,i,c) - Vload_sim(k,i,c);
            DVp_sim(k,i,c) = (DV_sim(k,i,c) / Vsource_sim(k,i,c)) * 100;

            %% Teorik hesap
            % Akim Simulink'ten alinmaz.
            % Teorik olarak P, V_LL ve cosphi ile hesaplanir.

            I_theory(k,i,c) = I_calc;

            DV_theory(k,i,c) = I_theory(k,i,c) * ...
                (R_km*cosphi + X_km*sinphi) * line_length_km;

            Vload_theory(k,i,c) = V_ph - DV_theory(k,i,c);
            DVp_theory(k,i,c)   = (DV_theory(k,i,c) / V_ph) * 100;

            %% Hata yuzdesi
            if abs(DV_theory(k,i,c)) > 1e-12
                error_pct(k,i,c) = abs(DV_sim(k,i,c) - DV_theory(k,i,c)) ...
                    / abs(DV_theory(k,i,c)) * 100;
            else
                error_pct(k,i,c) = 0;
            end

            %% Komut penceresine detay yazdir
            fprintf('\n============================================================\n');
            fprintf('Kablo = %s | Uzunluk = %d m | cos(phi) = %.1f\n', ...
                kablo(k).kesit, line_length_m, cosphi);
            fprintf('------------------------------------------------------------\n');

            fprintf('Simulink Parametreleri:\n');
            fprintf('  R_line              = %.6f ohm\n', R_line);
            fprintf('  L_line              = %.8e H\n', L_line);
            fprintf('  Q_load              = %.2f var\n', Q_load);

            fprintf('\nSimulasyon Sonuclari:\n');
            fprintf('  Vkaynak_fn RMS       = %.4f V\n', Vsource_sim(k,i,c));
            fprintf('  Vyuk_fn RMS          = %.4f V\n', Vload_sim(k,i,c));
            fprintf('  I_sim RMS            = %.4f A\n', I_sim(k,i,c));
            fprintf('  DeltaV_sim faz       = %.4f V\n', DV_sim(k,i,c));
            fprintf('  DeltaV_sim %%         = %.4f %%\n', DVp_sim(k,i,c));

            fprintf('\nTeorik Sonuclar:\n');
            fprintf('  I_theory RMS         = %.4f A\n', I_theory(k,i,c));
            fprintf('  DeltaV_theory faz    = %.4f V\n', DV_theory(k,i,c));
            fprintf('  Vload_theory_fn      = %.4f V\n', Vload_theory(k,i,c));
            fprintf('  DeltaV_theory %%      = %.4f %%\n', DVp_theory(k,i,c));
            fprintf('  Hata                 = %.4f %%\n', error_pct(k,i,c));
            fprintf('============================================================\n');

        end
    end
end

%% =========================
% OZET TABLO YAZDIRMA
%% =========================
for c = 1:numCos

    fprintf('\n\n###################################################################\n');
    fprintf('cos(phi) = %.1f | Q_load = %.2f var\n', ...
        cosphi_values(c), Q_values(c));
    fprintf('###################################################################\n');

    for k = 1:numKablo

        fprintf('\n--- %s ---\n', kablo(k).kesit);
        fprintf('Uzunluk(m)\tI_th(A)\t\tI_sim(A)\tVkaynak(V)\tVyuk(V)\t\tDV_sim(V)\tDV_th(V)\tDV_sim(%%)\tDV_th(%%)\tHata(%%)\n');

        for i = 1:numL

            fprintf('%d\t\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\n', ...
                L_m(i), ...
                I_theory(k,i,c), ...
                I_sim(k,i,c), ...
                Vsource_sim(k,i,c), ...
                Vload_sim(k,i,c), ...
                DV_sim(k,i,c), ...
                DV_theory(k,i,c), ...
                DVp_sim(k,i,c), ...
                DVp_theory(k,i,c), ...
                error_pct(k,i,c));

        end
    end
end

%% =========================
% GRAFIK 1:
% Her kablo icin farkli cosphi degerlerinde teorik yuzde gerilim dusumu
%% =========================
for k = 1:numKablo

    figure;
    plot(L_m, DVp_theory(k,:,1), '-o', 'LineWidth', 1.5); hold on;
    plot(L_m, DVp_theory(k,:,2), '-s', 'LineWidth', 1.5);
    plot(L_m, DVp_theory(k,:,3), '-d', 'LineWidth', 1.5);

    grid on;
    xlabel('Hat uzunlugu (m)');
    ylabel('Gerilim dusumu (%)');
    title([kablo(k).kesit ' icin uzunluga bagli teorik gerilim dusumu']);
    legend('cos\phi = 0.8', 'cos\phi = 0.9', 'cos\phi = 1.0', ...
        'Location', 'northwest');

end

%% =========================
% GRAFIK 2:
% Her cosphi icin farkli kablo kesitlerinde teorik yuzde gerilim dusumu
%% =========================
for c = 1:numCos

    figure;
    plot(L_m, DVp_theory(1,:,c), '-o', 'LineWidth', 1.5); hold on;
    plot(L_m, DVp_theory(2,:,c), '-s', 'LineWidth', 1.5);
    plot(L_m, DVp_theory(3,:,c), '-d', 'LineWidth', 1.5);

    grid on;
    xlabel('Hat uzunlugu (m)');
    ylabel('Gerilim dusumu (%)');
    title(['cos\phi = ' num2str(cosphi_values(c)) ...
        ' icin teorik gerilim dusumu']);
    legend('4 mm^2', '6 mm^2', '10 mm^2', ...
        'Location', 'northwest');

end

%% =========================
% GRAFIK 3:
% Her kablo icin farkli cosphi degerlerinde teorik yuk faz-notr gerilimi
%% =========================
for k = 1:numKablo

    figure;
    plot(L_m, Vload_theory(k,:,1), '-o', 'LineWidth', 1.5); hold on;
    plot(L_m, Vload_theory(k,:,2), '-s', 'LineWidth', 1.5);
    plot(L_m, Vload_theory(k,:,3), '-d', 'LineWidth', 1.5);

    grid on;
    xlabel('Hat uzunlugu (m)');
    ylabel('Yuk faz-notr gerilimi (V)');
    title([kablo(k).kesit ' icin teorik yuk faz-notr gerilimi']);
    legend('cos\phi = 0.8', 'cos\phi = 0.9', 'cos\phi = 1.0', ...
        'Location', 'southwest');

end

%% =========================
% GRAFIK 4:
% Simulasyon ve teorik faz gerilim dusumu karsilastirmasi
%% =========================
for c = 1:numCos

    for k = 1:numKablo

        figure;
        plot(L_m, squeeze(DV_theory(k,:,c)), '-o', 'LineWidth', 1.5); hold on;
        plot(L_m, squeeze(DV_sim(k,:,c)), '-s', 'LineWidth', 1.5);

        grid on;
        xlabel('Hat uzunlugu (m)');
        ylabel('Faz gerilim dusumu (V)');
        title([kablo(k).kesit ' | cos\phi = ' ...
            num2str(cosphi_values(c)) ' | Teorik vs Simulasyon']);
        legend('Teorik', 'Simulasyon', 'Location', 'northwest');

    end
end

%% =========================
% YARDIMCI FONKSIYON
%% =========================
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
