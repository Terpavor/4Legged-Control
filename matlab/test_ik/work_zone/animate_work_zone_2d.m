% Matlab R2014b
clc
clear all
close all

save_gif_flag = false;
    gif_delay = 1/20; % с
    first_frame_flag = true;
    gif_filename = 'work_zone5.gif';

point_count = 55;
%% Дано:
global L

L(1) = 0.1;
L(2) = 0.5;
L(3) = 0.5;

Phi_min_3_range = -180:10:0;
Phi_min_3_range = [Phi_min_3_range fliplr(Phi_min_3_range)];

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
        % Вычисляем новые положения вершин(x1-3,y1-3)
        R = fk_rrr(Phi);
        % Координаты стопы (x3,y3)
        point_cloud_out(i,:) = R(1:3,end)';
    end

    shp = alphaShape(point_cloud_out(:,1), point_cloud_out(:,3),0.03);
    
%         fprintf(  'Точка(\t x,\t\t y,\t\t z\t ), относ(абс) угол\n');
%         fprintf(  '№%1.d\t (%6.3f, %6.3f, %6.3f ), %3.f°(%3.f°)\n', ...
%                         cat(1, 1:4, R{1}(1:3,1:4), [rad2deg(wrapTo2Pi(Phi')) NaN ], ...
%                         rad2deg( wrapToPi([Phi(1), cumsum(Phi(2:end))', NaN]) ) ) );
%         fprintf(  'Ошибка: %3.3f\n', abs( norm(G - R{1}(1:3,4)) )  );
        
    clc;
    fprintf('Выполнено: %2.f%%\n', 100*ii/iter_max);

    plot(shp, 'FaceColor', [0 0.5 0.5]);%,'FaceColor', hsv2rgb([mod(2*ii,iter_max)/iter_max 1 1]));
    title(sprintf(...
'Рабочая зона в плоскости ноги\n\\phi_{min}^3=%+3.0f; \\phi_{max}^3=%+3.0f', ...
        Phi_min(3), Phi_max(3)), 'Interpreter', 'Tex', 'FontSize', 18, ...
        'Fontname', 'Consolas');
    axis equal;
    axis(  [-sum(L(2:3))	sum(L(2:3)) ...
            -sum(L)     	0.4]);
    
    
    grid on
    % Принудительно отрисовываем график без pause
    drawnow;


    if save_gif_flag
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
    end
end










