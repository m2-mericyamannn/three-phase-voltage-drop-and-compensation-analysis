%% ============================================================
% RAPOR ICIN DUZENLENMIS GRAFIKLER
% Hesaplamalar bittikten sonra calistirilir.
%% ============================================================

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'Simulink'));

%% GRAFIK 1:
% Hat uzunluguna bagli gerilim dusumu
% 6 mm^2 kablo icin cosphi degerlerinin karsilastirmasi

selected_kablo_index = 2;   % 1: 4 mm^2, 2: 6 mm^2, 3: 10 mm^2

figure;
hold on;
grid on;
box on;

plot(L_m, squeeze(DVp_theory(selected_kablo_index,:,1)), '-o', 'LineWidth', 2);
plot(L_m, squeeze(DVp_theory(selected_kablo_index,:,2)), '-s', 'LineWidth', 2);
plot(L_m, squeeze(DVp_theory(selected_kablo_index,:,3)), '-d', 'LineWidth', 2);

xlabel('Hat Uzunluğu (m)');
ylabel('Gerilim Düşümü (%)');
title('Hat Uzunluğuna Bağlı Gerilim Düşümü (6 mm^2)');
legend('cos\phi = 0.8', 'cos\phi = 0.9', 'cos\phi = 1.0', ...
    'Location', 'northwest');

set(gca, 'FontSize', 11);


%% GRAFIK 2:
% Guc faktorune bagli gerilim dusumu
% 100 m hat uzunlugu icin farkli kablo kesitleri

selected_length = 100;
[~, idxL] = min(abs(L_m - selected_length));

figure;
hold on;
grid on;
box on;

plot(cosphi_values, squeeze(DVp_theory(1,idxL,:)), '-o', 'LineWidth', 2);
plot(cosphi_values, squeeze(DVp_theory(2,idxL,:)), '-s', 'LineWidth', 2);
plot(cosphi_values, squeeze(DVp_theory(3,idxL,:)), '-d', 'LineWidth', 2);

xlabel('Güç Faktörü (cos\phi)');
ylabel('Gerilim Düşümü (%)');
title('Güç Faktörüne Bağlı Gerilim Düşümü (100 m)');
legend('4 mm^2', '6 mm^2', '10 mm^2', ...
    'Location', 'northeast');

set(gca, 'FontSize', 11);


%% GRAFIK 3:
% Kablo kesitine bagli gerilim dusumu
% 100 m ve cosphi = 0.8 icin

selected_length = 100;
selected_cosphi = 0.8;

[~, idxL] = min(abs(L_m - selected_length));
[~, idxC] = min(abs(cosphi_values - selected_cosphi));

kesit_values = [4 6 10];
DV_kesit = squeeze(DVp_theory(:,idxL,idxC));

figure;
bar(kesit_values, DV_kesit);
grid on;
box on;

xlabel('Kablo Kesiti (mm^2)');
ylabel('Gerilim Düşümü (%)');
title('Kablo Kesitine Bağlı Gerilim Düşümü (100 m, cos\phi = 0.8)');

set(gca, 'FontSize', 11);


%% GRAFIK 4:
% Teorik ve simulasyon karsilastirmasi
% 6 mm^2, cosphi = 0.8 icin

selected_kablo_index = 2;
selected_cosphi = 0.8;

[~, idxC] = min(abs(cosphi_values - selected_cosphi));

figure;
hold on;
grid on;
box on;

plot(L_m, squeeze(DVp_theory(selected_kablo_index,:,idxC)), '-o', 'LineWidth', 2);
plot(L_m, squeeze(DVp_sim(selected_kablo_index,:,idxC)), '-s', 'LineWidth', 2);

xlabel('Hat Uzunluğu (m)');
ylabel('Gerilim Düşümü (%)');
title('Teorik ve Simülasyon Gerilim Düşümü Karşılaştırması (6 mm^2, cos\phi = 0.8)');
legend('Teorik', 'Simülasyon', 'Location', 'northwest');

set(gca, 'FontSize', 11);