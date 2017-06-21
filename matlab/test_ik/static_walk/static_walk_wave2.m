function trajectory = static_walk_wave2(R, e, step_vector, ground_height, traj_point_count)

    global leg_count
    
    persistent leg_i first_call
    
    if isempty(first_call) % ������ ����� �������
        leg_i = 1; % ������ ����
        first_call = 1;
    else
        leg_i = leg_i + 1; % ��������� ����
        if leg_i > 4
            leg_i = 1;
        end
    end
    % leg_i = legs_on_ground(R, ground_height);
    
%   ������� ��� ������(��� ������):
%
%   front
%   
%   2---3
%   |   |
%   |   |
%   1---4
%
%   back
    
    % ������������������ �����
    leg_step_chain = [1 3 4 2];%[4 3 1 2];%;
    % ������ ��������� ����, ������� ����� ������ ���
    next_step_leg_i = leg_step_chain(leg_i);
    % ������� ���, ������� ��������� �� �����
    next_leg_i_on_ground = 1:4;
    next_leg_i_on_ground(next_leg_i_on_ground == next_step_leg_i) = [];
    % �������� ������ ������� �� �����(��������, �� ����������� �����������
    % � ������)
    CoM_proj = get_CoM_projection(ground_height);
    % �������������� �������������, ����� next_step_leg_i ����� ��� �������
    supporting_polygon = get_supporting_polygon( ...
        R(next_leg_i_on_ground), ground_height);
    
%     % ���������, ������ �� ��������������� �������������� ������ ���������
%     % �������� ������ �������
%     [in,~] = inpolygon(CoM_proj(1), CoM_proj(2), ...
%         supporting_polygon(1,:), supporting_polygon(2,:));
%     % ���� ��� - ���� ����������� ����� ������� ���� ������
%     %
    IP = [0 0];

    % ���������, ������ �� ��������������� �������������� ������ ���������
    % �������� ������ �������
    [in,~] = inpolygon(CoM_proj(1), CoM_proj(2), ...
        supporting_polygon(1,:), supporting_polygon(2,:));
    % ���� ��� - ���� ����������� ����� ������� ���� ������
    if ~in
        % �������� ����� �������� ��������������
        supporting_polygon = [supporting_polygon, supporting_polygon(:,1)];

        % ���� ����� ����������� �������� �������������� � ������ y = 0;
        [xi,yi] = polyxpoly([-10 10],[0 0], ...
            supporting_polygon(1,:)',supporting_polygon(2,:)');
        IP = [xi, yi];
        % �������� ������� � ������ ������� �����
        [~,idx] = min(abs(xi));
        IP = IP(idx,:);
        % ������ ���������, ����� ����� ���������� ������, � �� ��
        % ������� �������� ��������������
        IP(1) = IP(1) + sign(IP(1))*0.3;
    end

    for i = 1:leg_count

        if any(i == next_leg_i_on_ground)
            disp('atata');
            disp(i);
            %g = [-IP(1)*0.1 + e{i}(1); -IP(2) + e{i}(2); ground_height];
            g = [e{i}(1)-0.1; -IP(2) +  e{i}(2); ground_height];
            trajectory{i} = cyclogram_CoM_shift(e{i}, g, traj_point_count)';
        else
            
            next_leg_e = e{next_step_leg_i};
            next_leg_g = next_leg_e + step_vector';

%             for i = next_leg_i_on_ground
%                 trajectory{i} = cyclogram_CoM_shift(e{i}, e{i}, traj_point_count)';
%             end
            trajectory{next_step_leg_i} = cyclogram_make_one_step(...
                next_leg_e, next_leg_g, traj_point_count)';

        end
    end
    
end