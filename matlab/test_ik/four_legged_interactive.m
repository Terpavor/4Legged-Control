% Matlab R2014b
clc
clear all
close all
addpath('./auxiliary')
addpath('./kinematics')
%% Дано:
global L

L(1) = 0.2;
L(2) = 0.6;
L(3) = 0.5;

leg_count = 4;

x_shift = 0.8;
y_shift = 0.4;
z_shift = -0.1; 
% положение системы координат(СК) ноги в СК робота
leg(1).pos = [+x_shift +y_shift z_shift]';
leg(2).pos = [+x_shift -y_shift z_shift]';
leg(3).pos = [-x_shift +y_shift z_shift]';
leg(4).pos = [-x_shift -y_shift z_shift]';

Phi(1) = deg2rad(0);
Phi(2) = deg2rad(320);
Phi(3) = deg2rad(110); Phi = Phi';
for i=1:leg_count;
    leg(i).angles = Phi;
end

leg(1).sign = -1;
leg(2).sign = -1;
leg(3).sign = +1;
leg(4).sign = +1;


for i=1:leg_count;
    R{i} = forward_kinematics(leg(i).angles); % положение звеньев при заданных углах
    R{i} = R{i} + repmat(leg(i).pos, [1 4]); % СК ноги -> СК робота
    g{i} = R{i}(1:3,end); % координаты стопы
end

G = g{1};

%% Отображение
% Окно
hFig = figure('Position', [50, 50, 1000, 800]);

% График
hPlot(1) = plot3(0, 0, 0, ...
                 'Color', 'c', 'LineWidth', 1, ...
                 'Marker', '.', 'MarkerSize', 15, 'MarkerEdgeColor', 'g');
hPlot(2) = copyobj(hPlot(1),gca); 
hPlot(3) = copyobj(hPlot(1),gca); 
hPlot(4) = copyobj(hPlot(1),gca); 
hold off
axis equal;
axis_limits = [ -sum(L(2:end))-x_shift	sum(L(2:end))+x_shift ...
                -sum(L)-y_shift         sum(L)+y_shift ...
                -sum(L)+z_shift         sum(L)];
axis(axis_limits);

grid on
xlabel('x');
ylabel('y');
zlabel('z');
title('4 leg');
campos([2 2 1]);
drawAxes(3, [0 0 0 0.3], {'x', 'y', 'z'});

% Подписи вершин
% for i=1:leg_count;
%     for j=1:4%[1 3 4]
%         hText(j) = text(R{i}(1,j), R{i}(2,j), R{i}(3,j),num2str(j));
%     end
% end

% Последние точки траектории
% nPoints = 20; % количество
% iPoints = 1; % номер последней точки
% for i=1:nPoints
%     hPoint(i) = text(g(1), g(2), g(3), '.', 'Color', 'magenta');
% end

% Слайдеры
str = {'F1','F2','F3'};
for i=1:3
    hSlider(i) = uicontrol( 'Parent', hFig, 'Style', 'slider', ...
                            'Position',[40, 20*(3-i), 460, 20], ...
                            'value', Phi(i), 'min', 0, 'max', 2*pi);
    hLabel(i) = uicontrol('style','text', 'String', str{i}, ...
        'Position', [0 20*(3-i) 40 20], 'FontSize', 12,'FontName','symbol');
end
str = {'x','y','z'};
for i=4:6
    hSlider(i) = uicontrol( 'Parent', hFig, 'Style', 'slider', ...
                            'Position',[500, 20*(6-i), 460, 20], ...
                            'value', G(i-3), ...
                            'min', axis_limits(2*(i-3)-1), ...
                            'max', axis_limits(2*(i-3)) );
    hLabel(i) = uicontrol('style','text', 'String', str{i-3}, ...
        'Position', [500+460, 20*(6-i) 40 20], 'FontSize', 12);
end

%% Анимация
% Настройки анимации
frame_frequency = 100; % кадров в секунду
delay = 1/frame_frequency; % секунд

last_G = G; % [0 0 0]';
last_Phi = [0 0 0]';
warn_msg = '';
while ishandle(hFig)
    % Обновляем заданные углы: читаем значения со слайдеров
    for j=1:3
        Phi(j) = get(hSlider(j),'Value');
    end
    % Обновляем заданные координаты: читаем значения со слайдеров
    for j=4:6
        G(j-3) = get(hSlider(j),'Value');
    end
    
    
    if(any(G ~= last_G) || any(Phi ~= last_Phi))
        % Вычисляем новые углы, если заданы новые координаты
        if(any(G ~= last_G))
            for i=1:leg_count;
                g{i} = G; % копируем новые координаты на все 4 ноги
                g_leg{i} = g{i}; % оставляем координаты в СК ноги
                %g_leg{i} = g{i} - leg(i).pos; % СК ноги -> СК робота
                [leg(i).angles, warn_msg] = ...
                    inverse_kinematics(g_leg{i}, leg(i).sign);
            end
            Phi = leg(1).angles;
        end
        % Копируем новые углы(если заданы) на все 4 ноги
        if(any(Phi ~= last_Phi) && ~any(G ~= last_G))
            for i=1:leg_count;
                leg(i).angles = Phi;
            end
        end
        % Вычисляем новые положения вершин
        for i=1:leg_count;
            R{i} = forward_kinematics(leg(i).angles); % в СК ноги
            R{i} = R{i} + repmat(leg(i).pos, [1 4]); % СК ноги -> СК робота     
        end
        % Обновляем координаты, если заданы новые углы
        if(any(Phi ~= last_Phi) && ~any(G ~= last_G))
            for i=1:leg_count;
                g{i} = R{i}(1:3,end);
            end
            G = g{1};
        end
        % Обновляем график
        for i=1:4;
            set(hPlot(i), 'XData',R{i}(1,:), 'YData',R{i}(2,:), 'ZData', R{i}(3,:));
        end
        % Обновляем слайдеры
        for j=1:3 % углы
            set(hSlider(j),'Value', Phi(j));
        end
        for j=4:6 % координаты
            set(hSlider(j),'Value', G(j-3));
        end
        % Принудительно отрисовываем график без pause
        drawnow;
        % Выводим в консоль координаты и углы
        clc;
        fprintf(  'Точка(\t x,\t\t y,\t\t z\t ), относ(абс) угол\n');
        fprintf(  '№%1.d\t (%6.3f, %6.3f, %6.3f ), %3.f°(%3.f°)\n', ...
                        cat(1, 1:4, R{1}(1:3,1:4), [rad2deg(wrapTo2Pi(Phi')) NaN ], ...
                        rad2deg( wrapToPi([Phi(1), cumsum(Phi(2:end))', NaN]) ) ) );
        fprintf(  'Ошибка: %3.3f\n', abs( norm(G - R{1}(1:3,4)) )  );
        fprintf(2, warn_msg, 'verbose', 'off'  );
    end
    
    
    last_G = G;
    last_Phi = Phi;
    pause(delay)
end


%%
% 
% beta = 0.55;
% F(1) = deg2rad(-160);
% F(2) = deg2rad(-90);
% F(3) = deg2rad(-90);
% F(4) = deg2rad(-90);
% F = F';
% g(1) = 0.5;
% g(2) = 0.6;
% g(3) = 0.5;
% 
% g = g';
% e = A(F);
% 
% error = g-e;
% i = 0;
% d_F = zeros(4,1);
% 
% R = Afull([F; 0]);
% 
% perm_bin = PermsRep( [-1 1], length(L(3:end)) )
% len_for_perm = repmat(L(3:end), length(perm_bin), 1)
% perm_len = perm_bin.*len_for_perm
% sum_perm_len = abs(sum(perm_len, 2) + L(2))
% min_sum = min(sum_perm_len)
% 
% dist = g - [0 L(1) 0]';
% if    ( norm(dist) > L(2)+L(3)+L(4) )
%     text(g(1),g(3),g(2),'too far');
%     g = dist/norm(dist)*(L(2)+L(3)+L(4)) + [0 L(1) 0]'
%     
% elseif( norm(dist) < min_sum )
%     text(g(1),g(3),g(2),'too close');
%     g = dist/norm(dist)*min_sum + [0 L(1) 0]'
%     
% end
% text(g(1),g(3),g(2),'end');
% 
% while( norm(error)>0.1 && i<300 && ishandle(hFig))
%     J = jacobianest(@A,F)';
%     J_inv = pinv(J);
%     
%     error = g-e;
%     d_e = beta*error;
%     d_F = J_inv'*d_e;
% %     d_F(1) = J(:,1)'*d_e;
% %     d_F(2) = J(:,2)'*d_e;
% %     d_F(3) = J(:,3)'*d_e;
%     F = F+d_F;
%     e = A(F);
%     
%     R = Afull([F; 0]);
%     refreshdata;
%     for j=1:5
%         set(hText(j), 'Position', [R(1,j), R(3,j), R(2,j)]);
%     end
%     
%     i=i+1;
%     %text(R(1,4), R(3,4), R(2,4),'.');
%     pause(0.005);
%     
%     
% end
% i
% return
