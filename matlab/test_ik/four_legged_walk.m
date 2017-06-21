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
    gif_filename = 'four_legged_walk.gif';
%% Дано:
global L

L(1) = 0.2;
L(2) = 0.5;
L(3) = 0.6;

ground_height = -1;

leg_count = 4;

% сдвиг ноги относительно начала координат
x_shift = 0.8;
y_shift = 0.4;
z_shift = -0.0;
% положение систем координат(СК) ног относительно СК робота
leg(1).pos = [+x_shift +y_shift z_shift]';
leg(2).pos = [-x_shift -y_shift z_shift]';
leg(3).pos = [+x_shift -y_shift z_shift]';
leg(4).pos = [-x_shift +y_shift z_shift]';

% для выбора решения(конфигурации) инверсной кинематики
leg(1).sign = -1;
leg(2).sign = +1;
leg(3).sign = -1;
leg(4).sign = +1;

point_1 = [-0.3 0 ground_height]'; % начальная точка шага в СК робота
point_2 = [+0.3 0 ground_height]'; % конечная точка шага в СК робота

% флаг, означающий, что в текущей фазе движения надо сдвигать тело робота
shift_flag = false;

traj_point_count = 50;

trajectory_step = cyclogram_make_one_step( point_1, point_2, traj_point_count );
trajectory_shift = cyclogram_CoM_shift( point_2, point_1, traj_point_count );

% задаём начальное положение
for i=1:leg_count;
    g{i} = trajectory_step(1:3,1);
    [leg(i).angles,~] = inverse_kinematics(g{i}, +1);    
    
    R{i} = forward_kinematics(leg(i).angles); % положение звеньев при заданных углах
    R{i} = R{i} + repmat(leg(i).pos, [1 4]); % СК ноги -> СК робота
end

%% Отображение
% Окно
hFig = figure('Position', [50, 50, 1000, 800]);

% График
% ------------------- Стиль для печати ------------------------------------
% hPlot(1) = plot3(0, 0, 0, ...       % нога 1
%                  'Color', 'k', 'LineWidth', 1, ...
%                  'Marker', '.', 'MarkerSize', 15, 'MarkerEdgeColor', 'k');
% hPlot(2) = copyobj(hPlot(1),gca);   % нога 2 
% hPlot(3) = copyobj(hPlot(1),gca);   % нога 3
% hPlot(4) = copyobj(hPlot(1),gca);   % нога 4
% hPlot(5) = copyobj(hPlot(1),gca);   % поддерживающий многоугольник
% hPlot(6) = copyobj(hPlot(1),gca);   % проекция центра тяжести на "землю"
% hPlot(7) = copyobj(hPlot(1),gca);   % корпус
% set( hPlot(5),   'Color', 'k', 'LineWidth', 0.5, ...
%                  'Marker', 'o', 'MarkerSize', 6, 'MarkerEdgeColor', 'k');
% set( hPlot(6),  'XData',0, 'YData',0, 'ZData',ground_height, ...
%                 'MarkerEdgeColor', 'k', 'Marker', '.', 'MarkerSize', 15 );
% 
% robot_case = [  leg(1).pos, leg(3).pos, leg(2).pos, leg(4).pos leg(1).pos];
% set( hPlot(7),  'XData',robot_case(1,:), ...
%                 'YData',robot_case(2,:), ...
%                 'ZData',robot_case(3,:) );
% ------------------- Обычный стиль ---------------------------------------
hPlot(1) = plot3(0, 0, 0, ...       % нога 1
                 'Color', 'c', 'LineWidth', 1, ...
                 'Marker', '.', 'MarkerSize', 15, 'MarkerEdgeColor', 'g');
hPlot(2) = copyobj(hPlot(1),gca);   % нога 2 
hPlot(3) = copyobj(hPlot(1),gca);   % нога 3
hPlot(4) = copyobj(hPlot(1),gca);   % нога 4
hPlot(5) = copyobj(hPlot(1),gca);   % поддерживающий многоугольник
hPlot(6) = copyobj(hPlot(1),gca);   % проекция центра тяжести на "землю"
set( hPlot(5),   'Color', 'g', 'LineWidth', 0.5, ...
                 'Marker', 'o', 'MarkerSize', 6, 'MarkerEdgeColor', 'r');
set( hPlot(6),  'XData',0, 'YData',0, 'ZData',ground_height, ...
                'MarkerEdgeColor', 'b', 'Marker', '.', 'MarkerSize', 15 );
% -------------------------------------------------------------------------
% copyobj здесь как аналог "hold on" для plot3

hold off
axis equal;
axis_limits = [ -sum(L(2:end))-x_shift	sum(L(2:end))+x_shift ...
                -sum(L)-y_shift         sum(L)+y_shift ...
                ground_height           sum(L)];
axis(axis_limits);

grid on
xlabel('x');
ylabel('y');
zlabel('z');
campos([2 2 1]);
drawAxes(3, [0 0 0 0.3], {'x', 'y', 'z'});


% Подписи ног
for i=1:leg_count
    hText(i) = text(leg(i).pos(1), leg(i).pos(2), leg(i).pos(3), num2str(i));
end

%% Анимация
% Настройки анимации
frame_frequency = 50; % кадров в секунду
delay = 1/frame_frequency; % секунд


traj_i = 1; % номер точки траектории
leg_i = 1; % номер ноги, которая делает шаг в текущей фазе
while ishandle(hFig)
    % Выбираем новую точку траектории
    if ~shift_flag
        g{leg_i} = trajectory_step(:,traj_i);
    else
        for i=1:leg_count;
            g{i} = trajectory_shift(:,traj_i);
        end
    end
    
    % Вычисляем новые углы
        for i=1:leg_count;
            g_leg{i} = g{i}; % оставляем координаты в СК ноги
            %g_leg{i} = g{i} - leg(i).pos; % СК ноги -> СК робота
            [leg(i).angles, ~] = inverse_kinematics(g_leg{i}, leg(i).sign);
        end
        Phi = leg(1).angles; % углы 1-й ноги - для вывода в консоль
    % Вычисляем новые положения вершин
        for i=1:leg_count;
            R{i} = forward_kinematics(leg(i).angles); % в СК ноги
            R{i} = R{i} + repmat(leg(i).pos, [1 4]); % СК ноги -> СК робота     
        end
    % Обновляем график
        for i=1:4;
            set(hPlot(i), 'XData',R{i}(1,:), 'YData',R{i}(2,:), 'ZData', R{i}(3,:));
        end        
    % Рисуем поддерживающий многоугольник
        % многоугольник, внутри которого должен находиться центр тяжести
        % для достижения статической устойчивости. Можно считать, что центр
        % тяжести находится в точке [0, 0](z сейчас не важен). Да, в этой 
        % программе центр тяжести вылезает на многоугольник.
        if ~shift_flag % если делаем шаг(3 ноги на земле)
            sp_i = 1:4;
            sp_i = sp_i(sp_i~=leg_i); % выбираем ноги, стоящие на земле
            
            supporting_polygon = zeros(3,leg_count);
            j = 1;
            for i = sp_i
                supporting_polygon(1:3,j) = R{i}(:,end);
                j = j+1;
            end
            supporting_polygon(1:3,j) = R{sp_i(1)}(:,end);
        else % если сдвигаем тело(все 4 ноги на земле)
            supporting_polygon = [  R{1}(:,end), ...
                                    R{3}(:,end), ...
                                    R{2}(:,end), ...
                                    R{4}(:,end), ...
                                    R{1}(:,end)]; % костыль для правильной отрисовки
        end
        supporting_polygon(3,:) = ground_height; % проецируем на землю
        set( hPlot(5),  'XData',supporting_polygon(1,:), ...
                        'YData',supporting_polygon(2,:), ...
                        'ZData',supporting_polygon(3,:) );
    % Принудительно отрисовываем график без pause
        drawnow;
    % Выводим в консоль координаты и углы
        clc;
        fprintf(  'Точка(\t x,\t\t y,\t\t z\t ), относ(абс) угол\n');
        fprintf(  '№%1.d\t (%6.3f, %6.3f, %6.3f ), %3.f°(%3.f°)\n', ...
                        cat(1, 1:4, R{1}(1:3,1:4), [rad2deg(wrapTo2Pi(Phi')) NaN ], ...
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
    
    traj_i = traj_i+1;
    if traj_i >= length(trajectory_step(1,:)) && ~shift_flag || ...
       traj_i >= length(trajectory_shift(1,:)) && shift_flag % зацикливаем движение
   
        traj_i = 1;
        
        if leg_i < 4 && ~shift_flag
            leg_i = leg_i + 1;  % двигаем следующую ногу
        elseif ~shift_flag
            leg_i = 1;
            shift_flag = true;  % теперь сдвигаем тело
        else
            shift_flag = false; % снова начнём двигать ноги
            
            if save_gif_flag
                return
            end
        end
    end
    if ~save_gif_flag
        pause(delay)
    end
end









