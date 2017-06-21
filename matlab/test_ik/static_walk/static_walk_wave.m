function trajectory = static_walk_wave(R, e, step_vector, ground_height, traj_point_count)

    global leg_count
    
    persistent phase
    persistent leg_i
    if isempty(phase) % первый вызов функции
        phase = 0; % фаза сдвига
        leg_i = 1; % первая нога
    else
        phase = ~phase; % меняем фазу
        if phase == 0 % если фаза сдвига
            leg_i = leg_i + 1; % следующая нога
            if leg_i > 4
                leg_i = 1;
            end
        end
    end
    % leg_i = legs_on_ground(R, ground_height);
    
%   индексы ног робота(вид сверху):
%
%   front
%   
%   2---3
%   |   |
%   |   |
%   1---4
%
%   back
    
    % последовательность шагов
    leg_step_chain = [4 3 1 2];%[1 2 3 4];
    % индекс следующей ноги, которая будет делать шаг
    next_step_leg_i = leg_step_chain(leg_i);
    % индексы ног, которые останутся на земле
    next_leg_i_on_ground = 1:4;
    next_leg_i_on_ground(next_leg_i_on_ground == next_step_leg_i) = [];
    % проекция центра тяжести на землю(заглушка, не учитываются препятствия
    % и прочее)
    CoM_proj = get_CoM_projection(ground_height);
    % поддерживающий многоугольник, когда next_step_leg_i будет уже поднята
    supporting_polygon = get_supporting_polygon( ...
        R(next_leg_i_on_ground), ground_height);
    
%     % проверяем, внутри ли поддерживающего многоугольника сейчас находится
%     % проекция центра тяжести
%     [in,~] = inpolygon(CoM_proj(1), CoM_proj(2), ...
%         supporting_polygon(1,:), supporting_polygon(2,:));
%     % если нет - надо переместить центр тяжести туда внутрь
%     %

    switch phase
        case 0 % фаза сдвига
            
            IP = [0 0];
            
            % проверяем, внутри ли поддерживающего многоугольника сейчас находится
            % проекция центра тяжести
            [in,~] = inpolygon(CoM_proj(1), CoM_proj(2), ...
                supporting_polygon(1,:), supporting_polygon(2,:));
            % если нет - надо переместить центр тяжести туда внутрь
            if ~in
                % замыкаем линию опорного многоугольника
                supporting_polygon = [supporting_polygon, supporting_polygon(:,1)];
                
                % ищем точки пересечения опорного многоугольника и прямой y = 0;
                [xi,yi] = polyxpoly([-10 10],[0 0], ...
                    supporting_polygon(1,:)',supporting_polygon(2,:)');
                IP = [xi, yi];
                % выбираем ближнюю к центру тяжести точку
                [~,idx] = min(abs(xi));
                IP = IP(idx,:)
                % вводим коррекцию, чтобы точка находилась внутри, а не на
                % границе опорного многоугольника
                IP(1) = IP(1) + sign(IP(1))*0.1
            end
            
            for i = 1:leg_count
                %g = e{i} + IC
                g = [-IP(1) + e{i}(1); -IP(2) + e{i}(2); ground_height];
                trajectory{i} = cyclogram_CoM_shift(e{i}, g, traj_point_count)';
                
                
                
%                 axis equal;
%                 axis_limits = [-1.7 1.7 -1 1];
%                 axis(axis_limits);
%                 grid on;
% 
%                 hold on
%                 g = [IC(1:2); ground_height];
%                 plot([e{i}(1) g(1)], [e{i}(2) g(2)], 'b') 
%                 plot(e{i}(1), e{i}(2), 'rx') 
%                 plot(g(1), g(2), 'gx')
% %                 plot([CoM_proj(1) IC(1)], [CoM_proj(2) IC(2)], 'b') 
% %                 plot(CoM_proj(1), CoM_proj(2), 'r*') 
% %                 plot(IC(1), IC(2), 'g*') 
%                 % замыкаем линию для графика
%                 supporting_polygon2 = [supporting_polygon, supporting_polygon(:,1)];
%                 plot(supporting_polygon2(1,:), supporting_polygon2(2,:),'-') 
%                 hold off
    
    
            end
%           trajectory_shift = cyclogram_CoM_shift( ...
%               CoM_proj, IC, traj_point_count );
            %trajectory = repmat({trajectory_shift'}, 1, 4);
            
        case 1 % фаза шага
            next_leg_e = e{next_step_leg_i};%R{next_step_leg_i}(:,end);
            next_leg_g = next_leg_e + step_vector';
            
            
%             trajectory_shift = cyclogram_CoM_shift( ...
%                 CoM_proj, CoM_proj, traj_point_count );
            %trajectory_step = cyclogram_make_one_step(e, g, traj_point_count);           
%             trajectory = repmat({trajectory_shift'}, 1, 4);
%             trajectory{next_step_leg_i} = trajectory_step';
%             
            for i = next_leg_i_on_ground
                trajectory{i} = cyclogram_CoM_shift(e{i}, e{i}, traj_point_count)';
            end
            trajectory{next_step_leg_i} = cyclogram_make_one_step(...
                next_leg_e, next_leg_g, traj_point_count)';
    end
    
    
    
    
    
    
    
    
    return;
    
    
%     if length(leg_i) == 4 % если все ноги на земле
%         next_leg_i = 1; % следующий шаг делает 1-я
%     end
%     if ~find(leg_i == 1) %
%         next_leg_i = 3;
%     end
%     if ~find(leg_i == 2)
%         next_leg_i = 3;
%     end
%     if ~find(leg_i == 3)
%         next_leg_i = 3;
%     end
%     if ~find(leg_i == 4)
%         next_leg_i = 3;
%     end
    
    L = linspace(0,2.*pi,6);
    xv = cos(L)';
    yv = sin(L)';

    rng default
    xq = randn(250,1);
    yq = randn(250,1);

    [in,on] = inpolygon(xq,yq, xv,yv);

    numel(xq(in))
    numel(xq(on))
    numel(xq(~in))

    figure

    plot(xv,yv) % polygon
    axis equal

    hold on
    plot(xq(in),yq(in),'r+') % points inside
    plot(xq(~in),yq(~in),'bo') % points outside
    hold off
    
    
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
    
    
    
    
end