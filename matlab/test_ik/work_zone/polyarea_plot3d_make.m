% Matlab R2014b
clc
clear all
close all

point_count = 55;
%% Дано:
global L

L(1) = 68.2;
L(2) = 97.8;
L(3) = 143;


Phi_min_2_range = linspace(-180, 0, 5);
Phi_min_3_range = linspace(-180, 0, 5);
[Phi_min_2,Phi_min_3] = meshgrid(Phi_min_2_range, Phi_min_3_range);
points_for_3d_plot_in = [Phi_min_2(:) Phi_min_3(:)];

area = zeros(size(Phi_min_2));
Phi_min_2
for jj = 1:length(Phi_min_2(1,:))
for ii = 1:length(Phi_min_2(:,1))
    
    Phi_min = [0 Phi_min_2(ii,jj) Phi_min_3(ii,jj)]; % 0 phi2 phi3
    Phi_max = [0 Phi_min_2(ii,jj)+180 Phi_min_3(ii,jj)+180]

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

    shp = alphaShape(point_cloud_out(:,1), point_cloud_out(:,3),7);
    
    [bf, P] = boundaryFacets(shp);
    % замыкаем, хотя polyarea как-то переваривает и разомкнутый полигон
    P(end+1,:) = P(1,:);
    area(ii, jj) = polyarea(P(:,1),P(:,2));
    
    [ii jj]

    figure;
    %fprintf()disp(ii/iter_max)
     plot(P(:,1), P(:,2));
     axis equal;
     grid on
     % Принудительно отрисовываем график без pause
     drawnow;
end
end

figure;
mesh(Phi_min_2,Phi_min_3, area);
xlabel('Phi2');
ylabel('Phi3');
zlabel('area');

%csvwrite('csv_polyarea.dat',[Phi_min_3_range', area]);







