% Matlab R2014b
clc
clear all
close all
addpath('./auxiliary')
addpath('./kinematics')

save_gif_flag = false;
    gif_delay = 1/20; % с
    first_frame_flag = true;
    gif_filename = 'leg_interactive.gif';
%% Дано:
global L

L(1) = 0.4;
L(2) = 0.5;
L(3) = 0.6;

Phi(1) = deg2rad(-30);
Phi(2) = deg2rad(160);
Phi(3) = deg2rad(90); Phi = Phi';


[Phi, warn_msg] = inverse_kinematics([1 1 1]', +1, 'trigonometric');

R = forward_kinematics(Phi); % положение звеньев при заданных углах
g = R(1:3,end); % координаты стопы
%% Отображение
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
campos([2 2 1]);
drawAxes(3, [0 0 0 0.3], {'x', 'y', 'z'});

% Подписи вершин
for i=1:4%[1 3 4]
    hText(i) = text(R(1,i), R(2,i), R(3,i),num2str(i));
end

% Последние точки траектории
nPoints = 30; % количество
iPoints{1} = 1; % номер последней точки
iPoints{2} = 1; % номер последней точки
for i=1:nPoints
    hPoint{1}(i) = text(g(1), g(2), g(3), '.', 'Color', 'magenta');
    hPoint{2}(i) = text(g(1), g(2), g(3), '.', 'Color', 'blue');
end

% Слайдеры
str = {'F1','F2','F3'};
for i=1:3
    hSlider{1}(i) = uicontrol( 'Parent', hFig, 'Style', 'slider', ...
                            'Position',[40, 20*(3-i), 460, 20], ...
                            'value', Phi(i), 'min', -pi, 'max', pi);
    hLabel{1}(i) = uicontrol('style','text', 'String', str{i}, ...
        'Position', [0 20*(3-i) 40 20], 'FontSize', 12,'FontName','symbol');
end
str = {'x','y','z'};
for i=1:3
    hSlider{2}(i) = uicontrol( 'Parent', hFig, 'Style', 'slider', ...
                            'Position',[500, 20*(3-i), 460, 20], ...
                            'value', g(i), 'min', -sum(L), 'max', sum(L));
    hLabel{2}(i) = uicontrol('style','text', 'String', str{i}, ...
        'Position', [500+460, 20*(3-i) 40 20], 'FontSize', 12);
end

%% Анимация
% Настройки анимации
frame_frequency = 10; % кадров в секунду
delay = 1/frame_frequency; % секунд

last_g = g; % [0 0 0]';
last_Phi = [0 0 0]';
warn_msg = '';
frame_i = 1;
while ishandle(hFig)
    for j=1:3
        % Обновляем заданные углы: читаем значения со слайдеров
        Phi(j) = get(hSlider{1}(j),'Value');
        % Обновляем заданные координаты: читаем значения со слайдеров
        g(j) = get(hSlider{2}(j),'Value');
    end
    
    
    if(any(g ~= last_g) || any(Phi ~= last_Phi))
        clc;
        % Вычисляем новые углы, если заданы новые координаты
        if(any(g ~= last_g))
            [Phi, warn_msg] = inverse_kinematics(g, -1, 'algebraic');
            
%             flag = false; 
%             [Phi, flag, warn_msg2] = angle_bounds_check(Phi);
%             warn_msg = sprintf('%s%s',warn_msg,warn_msg2);
%             if 0
%                 R2 = forward_kinematics(Phi2);
%                 g2 = R2(1:3,end);
%                 [Phi, warn_msg] = inverse_kinematics(g2);
%             end
        end
        % Вычисляем новые положения вершин
        R = forward_kinematics(Phi);
        % Обновляем координаты, если заданы новые углы
        if(any(Phi ~= last_Phi) && ~any(g ~= last_g))
            g = R(1:3,end);
        end
        % Обновляем график
        set(hPlot, 'XData',R(1,:), 'YData',R(2,:), 'ZData', R(3,:));
        % Обновляем слайдеры
        for j=1:3
            set(hSlider{1}(j),'Value', Phi(j)); % углы
            set(hSlider{2}(j),'Value', g(j));   % координаты
        end        
        % Обновляем подписи вершин
        for j=1:4
            set(hText(j), 'Position', [R(1,j), R(2,j), R(3,j)]);
        end        
        % Обновляем траекторию
        set(hPoint{1}(iPoints{1}),'Position', [g(1), g(2), g(3)]); % требуемая траектория
        set(hPoint{2}(iPoints{1}),'Position', [R(1,4), R(2,4), R(3,4)]); % реальная траектория
        iPoints{1} = mod(iPoints{1}, nPoints) + 1;
        iPoints{2} = mod(iPoints{2}, nPoints) + 1;
        % Принудительно отрисовываем график без pause
        drawnow;
        % Выводим в консоль координаты и углы
        %clc;
        fprintf(  'Точка(\t x,\t\t y,\t\t z\t ), относ(абс) угол\n');
        fprintf(  '№%1.d\t (%6.3f, %6.3f, %6.3f ), %3.f°(%3.f°)\n', ...
                        cat(1, 1:4, R(1:3,1:4), [rad2deg(wrapToPi(Phi')) NaN ], ...
                        rad2deg( wrapToPi([Phi(1), cumsum(Phi(2:end))', NaN]) ) ) );
        fprintf(  'Ошибка: %3.3f\n', abs( norm(g - R(1:3,4)) )  );
        fprintf(2, warn_msg, 'verbose', 'off');
    end
    
    if save_gif_flag
        % получаем координаты графика в пикселях, без лишних границ
        % получаем координаты графика в пикселях, без лишних границ
        figure_pos = get(gcf, 'Position'); % x left, y bottom, width, height
        % сохраняем очередной кадр
        frame = getframe(1);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im,256);

        if first_frame_flag;
            imwrite(imind,cm,gif_filename,'gif', 'Loopcount',inf, 'DelayTime',gif_delay);
            first_frame_flag = false;
        else
            imwrite(imind,cm,gif_filename,'gif','WriteMode','append', 'DelayTime',gif_delay);
        end
        
        if frame_i > 100
            disp('gif end!');
            return;
        end
    end
    
    last_g = g;
    last_Phi = Phi;
    frame_i = frame_i+1;
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
