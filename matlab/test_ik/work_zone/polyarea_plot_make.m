% Matlab R2014b
clc
clear all
close all

point_count = 45;
%% Дано:
global L

L(1) = 0.1;
L(2) = 0.5;
L(3) = 0.5;
% L(1) = 68.2;
% L(2) = 97.8;
% L(3) = 143;

Phi_min_3_range = -180:10:0;
area = zeros(size(Phi_min_3_range));

iter_max = length(Phi_min_3_range);
for ii = 1:iter_max
    
    Phi_min_3 = Phi_min_3_range(ii);
    
    Phi_min = [0 -90            Phi_min_3];
    Phi_max = [0 Phi_min(2)+180 Phi_min(3)+180];

%% Облако точек в углах(="обобщённых координатах")
    range{1} = linspace(deg2rad(Phi_min(2)),deg2rad(Phi_max(2)),point_count);
    range{2} = linspace(deg2rad(Phi_min(3)),deg2rad(Phi_max(3)),point_count);
    [Phi2,Phi3] = meshgrid(range{1},range{2});

    Phi1 = zeros(size(Phi2));
    point_cloud_in = [Phi1(:) Phi2(:) Phi3(:)];
    point_cloud_out = zeros(length(point_cloud_in), 3);

%% Обработка

    for i=1:length(point_cloud_in)
        % Берем новую точку
        Phi = point_cloud_in(i,:)';
        % Вычисляем новые положения вершин(x1-4,y1-4)
        R = fk_rrr(Phi);
        % Конец пальца(x4,y4)
        point_cloud_out(i,:) = R(1:3,end)';
    end

    shp = alphaShape(point_cloud_out(:,1), point_cloud_out(:,3), 0.03);
    
    [bf, P] = boundaryFacets(shp);
    % замыкаем, хотя polyarea как-то переваривает и разомкнутый полигон
    P(end+1,:) = P(1,:);
    area(ii) = polyarea(P(:,1),P(:,2));

    %fprintf()disp(ii/iter_max)
     plot(P(:,1), P(:,2));
     axis equal;
     grid on
%     % Принудительно отрисовываем график без pause
     drawnow;
end

figure;
plot(Phi_min_3_range, area);

csvwrite('csv_polyarea.dat',[Phi_min_3_range', area]);







