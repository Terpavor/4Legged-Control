% Matlab R2014b
clc
clear all
close all
addpath('./auxiliary')
addpath('./kinematics')
addpath('./cyclogram')

show_animation = false;
%% Дано:
global L

L(1) = 0.2;
L(2) = 0.6;
L(3) = 0.5;

Phi = zeros(3,1);

%% Настройки графики
if show_animation

    g = [0 0 -1]';
    [Phi,~] = inverse_kinematics(g, -1);
    R = forward_kinematics(Phi);
    
    % Окно
    hFig = figure('Position', [50, 50, 1000, 800]);

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
    nPoints = 40; % количество
    iPoints = 1; % номер последней точки
    for i=1:nPoints
        hPoint(i) = text(g(1), g(2), g(3), '.', 'Color', 'magenta');
    end
end

%% Настройки теста
x_step = 0.1;
x_bounds = [-0.5 0.5];
repeat_count = 10;%10^1;

x_trajectory = (x_bounds(1):x_step:x_bounds(2))';
x_trajectory = [x_trajectory; flipud(x_trajectory)];
y_trajectory = 0.1*ones(size(x_trajectory));
z_trajectory = -1.1*ones(size(x_trajectory));


trajectory = [x_trajectory y_trajectory z_trajectory]';
trajectory = repmat(trajectory, 1, repeat_count);

method = {'algebraic', 'trigonometric', 'circles', 'jacobian'};


range{1} = linspace(-sum(L),sum(L),50);
range{2} = linspace(-sum(L),sum(L),50);
range{3} = linspace(-sum(L),sum(L),50);
[X,Y,Z] = meshgrid(range{1},range{2},range{3});

return

%% Тест

test_count = 4;
time = zeros(1, test_count);

fprintf('start\n'); 
for test_i = 1:test_count
    for i=1:length(trajectory)
        % Выбираем следующую точку траектории
        g = trajectory(:,i);
        tic; % - замеряем время
        % Вычисляем углы
        switch test_i
            case 1
                [Phi,~] = inverse_kinematics(g, -1, 'algebraic');
            case 2
                [Phi,~] = inverse_kinematics(g, -1, 'trigonometric');
            case 3
                [Phi,~] = inverse_kinematics(g, -1, 'circles');
            case 4
                [Phi,~] = inverse_kinematics(g, -1, 'jacobian', Phi, 0.1, 1.40);
        end
        time(test_i) = time(test_i)+toc; % - прибавляем время
        
        if show_animation
            if ~ishandle(hFig) % если окно закрыто
                return;
            end
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
        end
    end
    fprintf('test %d passed. time = %f s\n', test_i, time(test_i));
end
fprintf('end\n');  