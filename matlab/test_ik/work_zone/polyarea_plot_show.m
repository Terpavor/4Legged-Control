% Matlab R2014b
clc
clear all
close all

point_count = 55;
%% Дано:
global L

% L(1) = 0.1;
% L(2) = 0.5;
% L(3) = 0.5;
L(1) = 68.2;
L(2) = 97.8;
L(3) = 143;


P = csvread('csv_polyarea.dat');
size(P)

Phi_min_3_range = P(:,1);
work_zone_area = P(:,2);

work_zone_area = 100*work_zone_area/max(work_zone_area);

%%
figure;
plot(Phi_min_3_range, work_zone_area, 'k');
axis([Phi_min_3_range(1) Phi_min_3_range(end) 0 100]);
grid on
xlabel('{\phi}_3^{min}, градусов','Interpreter','Tex','FontSize',12);
ylabel('относительное значение площади, %','Interpreter','Tex','FontSize',12);
title({'Площадь сечения рабочей зоны', 'в плоскости Oxz в зависимости от {\phi}_3^{min}', ...
 '\phi_3^{max}=\phi_3^{min}+180\circ;  \phi_2^{max}=-90\circ;  \phi_2^{max}=90\circ'}, ...
 'Interpreter','Tex','FontSize',14, 'FontName', 'Consolas');

% %%
% figure;
% area(Phi_min_3_range, work_zone_area, 'FaceColor', 'cyan');
% a.EdgeAlpha  = 0.1;
% grid on

print('polyarea','-dpng')




