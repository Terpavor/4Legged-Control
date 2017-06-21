% Matlab R2014b
clc
clear all
close all
addpath('./auxiliary')
addpath('./kinematics')
addpath('./cyclogram')

save_gif_flag = true;
    gif_delay = 1/20; % с
    first_frame_flag = true;
    gif_filename = 'leg_walk.gif';
%% Дано:
global L

L(1) = 0.2;
L(2) = 0.6;
L(3) = 0.5;

Phi = zeros(3,1);

point_1 = [-0.5 0 -1]';
point_2 = [0.5 0 -1]';

traj_point_count = 30;

trajectory_step = cyclogram_make_one_step( point_1, point_2, traj_point_count );
trajectory_shift = cyclogram_CoM_shift( point_2, point_1, traj_point_count );
trajectory = [trajectory_step trajectory_shift];

g = trajectory(:,1);
[Phi,~] = inverse_kinematics(g, -1);
R = forward_kinematics(Phi);


%% Отображение
% Окно
hFig = figure('Position', [50, 50, 1000, 800], 'Color',[1 1 1]);

% График
hPlot = plot3(	R(1,:), R(2,:), R(3,:), ...
                'Color', 'c', 'LineWidth', 1, ...
                'Marker', '.', 'MarkerSize', 15, 'MarkerEdgeColor', 'g');
axis equal;
axis(  [-sum(L)	sum(L) ...
        -sum(L)	sum(L) ...
        -sum(L)	sum(L)]);
grid on
xlabel('x');
ylabel('y');
zlabel('z');
title('left front leg');
campos([1 2 1]);
drawAxes(3, [0 0 0 0.3], {'x', 'y', 'z'});

% Подписи вершин
for i=1:4
    hText(i) = text(R(1,i), R(2,i), R(3,i),num2str(i));
end

% Последние точки траектории
nPoints = 80; % количество
iPoints = 1; % номер последней точки
for i=1:nPoints
    hPoint(i) = text(g(1), g(2), g(3), '.', 'Color', 'magenta');
end

%% Анимация
% Настройки анимации
frame_frequency = 50; % кадров в секунду
delay = 1/frame_frequency; % секунд

i = 1;
while ishandle(hFig)   
    g = trajectory(:,i);
    
        % Вычисляем новые углы
        [Phi,~] = inverse_kinematics(g, -1);
        % Вычисляем новые положения вершин
        R = forward_kinematics(Phi);
        % Обновляем график
        set(hPlot, 'XData',R(1,:), 'YData',R(2,:), 'ZData', R(3,:));
        % Обновляем подписи вершин
        for j=1:4
            set(hText(j), 'Position', [R(1,j), R(2,j), R(3,j)]);
        end
        % Обновляем траекторию
        %set(hPoint(iPoints),'Position', [g(1), g(2), g(3)]); % требуемая траектория
        set(hPoint(iPoints),'Position', [R(1,4), R(2,4), R(3,4)]); % реальная траектория
        iPoints = mod(iPoints, nPoints) + 1;        
        % Принудительно отрисовываем график без pause
        drawnow;
        % Выводим в консоль координаты и углы
        clc;
        fprintf(  'Точка(\t x,\t\t y,\t\t z\t ), относ(абс) угол\n');
        fprintf(  '№%1.d\t (%6.3f, %6.3f, %6.3f ), %3.f°(%3.f°)\n', ...
                        cat(1, 1:4, R(1:3,1:4), [rad2deg(wrapToPi(Phi')) NaN ], ...
                        rad2deg( wrapToPi([Phi(1), cumsum(Phi(2:end))', NaN]) ) ) );
       
    if save_gif_flag
        % получаем координаты графика в пикселях, без лишних границ
        % получаем координаты графика в пикселях, без лишних границ
        figure_pos = get(gcf, 'Position'); % x left, y bottom, width, height
        w = figure_pos(3);
        h = figure_pos(4);
        plot_coord = plotboxpos(gca);
        plot_coord([1,3]) = plot_coord([1,3])*w;
        plot_coord([2,4]) = plot_coord([2,4])*h;
        % сохраняем очередной кадр
        frame = getframe(gcf, plot_coord);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im,256);

        if first_frame_flag;
            imwrite(imind,cm,gif_filename,'gif', 'Loopcount',inf, 'DelayTime',gif_delay);
            first_frame_flag = false;
        else
            imwrite(imind,cm,gif_filename,'gif','WriteMode','append', 'DelayTime',gif_delay);
        end
    end
    
    i = i+1;
    if i >= length(trajectory(1,:)) % зацикливаем движение
        i = 1;
        if save_gif_flag
            return;
        end
    end
    pause(delay)
end
