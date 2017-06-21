% Matlab R2014b
clc
clear all
close all
addpath('./auxiliary')
addpath('./kinematics')
addpath('./cyclogram')

save_gif_flag = true;
    gif_delay = 1/20; % �
    first_frame_flag = true;
    gif_filename = 'four_legged_walk.gif';
%% ����:
global L

L(1) = 0.2;
L(2) = 0.5;
L(3) = 0.6;

ground_height = -1;

leg_count = 4;

% ����� ���� ������������ ������ ���������
x_shift = 0.8;
y_shift = 0.4;
z_shift = -0.0;
% ��������� ������ ���������(��) ��� ������������ �� ������
leg(1).pos = [+x_shift +y_shift z_shift]';
leg(2).pos = [-x_shift -y_shift z_shift]';
leg(3).pos = [+x_shift -y_shift z_shift]';
leg(4).pos = [-x_shift +y_shift z_shift]';

% ��� ������ �������(������������) ��������� ����������
leg(1).sign = -1;
leg(2).sign = +1;
leg(3).sign = -1;
leg(4).sign = +1;

point_1 = [-0.3 0 ground_height]'; % ��������� ����� ���� � �� ������
point_2 = [+0.3 0 ground_height]'; % �������� ����� ���� � �� ������

% ����, ����������, ��� � ������� ���� �������� ���� �������� ���� ������
shift_flag = false;

traj_point_count = 50;

trajectory_step = cyclogram_make_one_step( point_1, point_2, traj_point_count );
trajectory_shift = cyclogram_CoM_shift( point_2, point_1, traj_point_count );

% ����� ��������� ���������
for i=1:leg_count;
    g{i} = trajectory_step(1:3,1);
    [leg(i).angles,~] = inverse_kinematics(g{i}, +1);    
    
    R{i} = forward_kinematics(leg(i).angles); % ��������� ������� ��� �������� �����
    R{i} = R{i} + repmat(leg(i).pos, [1 4]); % �� ���� -> �� ������
end

%% �����������
% ����
hFig = figure('Position', [50, 50, 1000, 800]);

% ������
% ------------------- ����� ��� ������ ------------------------------------
% hPlot(1) = plot3(0, 0, 0, ...       % ���� 1
%                  'Color', 'k', 'LineWidth', 1, ...
%                  'Marker', '.', 'MarkerSize', 15, 'MarkerEdgeColor', 'k');
% hPlot(2) = copyobj(hPlot(1),gca);   % ���� 2 
% hPlot(3) = copyobj(hPlot(1),gca);   % ���� 3
% hPlot(4) = copyobj(hPlot(1),gca);   % ���� 4
% hPlot(5) = copyobj(hPlot(1),gca);   % �������������� �������������
% hPlot(6) = copyobj(hPlot(1),gca);   % �������� ������ ������� �� "�����"
% hPlot(7) = copyobj(hPlot(1),gca);   % ������
% set( hPlot(5),   'Color', 'k', 'LineWidth', 0.5, ...
%                  'Marker', 'o', 'MarkerSize', 6, 'MarkerEdgeColor', 'k');
% set( hPlot(6),  'XData',0, 'YData',0, 'ZData',ground_height, ...
%                 'MarkerEdgeColor', 'k', 'Marker', '.', 'MarkerSize', 15 );
% 
% robot_case = [  leg(1).pos, leg(3).pos, leg(2).pos, leg(4).pos leg(1).pos];
% set( hPlot(7),  'XData',robot_case(1,:), ...
%                 'YData',robot_case(2,:), ...
%                 'ZData',robot_case(3,:) );
% ------------------- ������� ����� ---------------------------------------
hPlot(1) = plot3(0, 0, 0, ...       % ���� 1
                 'Color', 'c', 'LineWidth', 1, ...
                 'Marker', '.', 'MarkerSize', 15, 'MarkerEdgeColor', 'g');
hPlot(2) = copyobj(hPlot(1),gca);   % ���� 2 
hPlot(3) = copyobj(hPlot(1),gca);   % ���� 3
hPlot(4) = copyobj(hPlot(1),gca);   % ���� 4
hPlot(5) = copyobj(hPlot(1),gca);   % �������������� �������������
hPlot(6) = copyobj(hPlot(1),gca);   % �������� ������ ������� �� "�����"
set( hPlot(5),   'Color', 'g', 'LineWidth', 0.5, ...
                 'Marker', 'o', 'MarkerSize', 6, 'MarkerEdgeColor', 'r');
set( hPlot(6),  'XData',0, 'YData',0, 'ZData',ground_height, ...
                'MarkerEdgeColor', 'b', 'Marker', '.', 'MarkerSize', 15 );
% -------------------------------------------------------------------------
% copyobj ����� ��� ������ "hold on" ��� plot3

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


% ������� ���
for i=1:leg_count
    hText(i) = text(leg(i).pos(1), leg(i).pos(2), leg(i).pos(3), num2str(i));
end

%% ��������
% ��������� ��������
frame_frequency = 50; % ������ � �������
delay = 1/frame_frequency; % ������


traj_i = 1; % ����� ����� ����������
leg_i = 1; % ����� ����, ������� ������ ��� � ������� ����
while ishandle(hFig)
    % �������� ����� ����� ����������
    if ~shift_flag
        g{leg_i} = trajectory_step(:,traj_i);
    else
        for i=1:leg_count;
            g{i} = trajectory_shift(:,traj_i);
        end
    end
    
    % ��������� ����� ����
        for i=1:leg_count;
            g_leg{i} = g{i}; % ��������� ���������� � �� ����
            %g_leg{i} = g{i} - leg(i).pos; % �� ���� -> �� ������
            [leg(i).angles, ~] = inverse_kinematics(g_leg{i}, leg(i).sign);
        end
        Phi = leg(1).angles; % ���� 1-� ���� - ��� ������ � �������
    % ��������� ����� ��������� ������
        for i=1:leg_count;
            R{i} = forward_kinematics(leg(i).angles); % � �� ����
            R{i} = R{i} + repmat(leg(i).pos, [1 4]); % �� ���� -> �� ������     
        end
    % ��������� ������
        for i=1:4;
            set(hPlot(i), 'XData',R{i}(1,:), 'YData',R{i}(2,:), 'ZData', R{i}(3,:));
        end        
    % ������ �������������� �������������
        % �������������, ������ �������� ������ ���������� ����� �������
        % ��� ���������� ����������� ������������. ����� �������, ��� �����
        % ������� ��������� � ����� [0, 0](z ������ �� �����). ��, � ���� 
        % ��������� ����� ������� �������� �� �������������.
        if ~shift_flag % ���� ������ ���(3 ���� �� �����)
            sp_i = 1:4;
            sp_i = sp_i(sp_i~=leg_i); % �������� ����, ������� �� �����
            
            supporting_polygon = zeros(3,leg_count);
            j = 1;
            for i = sp_i
                supporting_polygon(1:3,j) = R{i}(:,end);
                j = j+1;
            end
            supporting_polygon(1:3,j) = R{sp_i(1)}(:,end);
        else % ���� �������� ����(��� 4 ���� �� �����)
            supporting_polygon = [  R{1}(:,end), ...
                                    R{3}(:,end), ...
                                    R{2}(:,end), ...
                                    R{4}(:,end), ...
                                    R{1}(:,end)]; % ������� ��� ���������� ���������
        end
        supporting_polygon(3,:) = ground_height; % ���������� �� �����
        set( hPlot(5),  'XData',supporting_polygon(1,:), ...
                        'YData',supporting_polygon(2,:), ...
                        'ZData',supporting_polygon(3,:) );
    % ������������� ������������ ������ ��� pause
        drawnow;
    % ������� � ������� ���������� � ����
        clc;
        fprintf(  '�����(\t x,\t\t y,\t\t z\t ), �����(���) ����\n');
        fprintf(  '�%1.d\t (%6.3f, %6.3f, %6.3f ), %3.f�(%3.f�)\n', ...
                        cat(1, 1:4, R{1}(1:3,1:4), [rad2deg(wrapTo2Pi(Phi')) NaN ], ...
                        rad2deg( wrapToPi([Phi(1), cumsum(Phi(2:end))', NaN]) ) ) );
    
                    
    if save_gif_flag
        % �������� ���������� ������� � ��������, ��� ������ ������
        % �������� ���������� ������� � ��������, ��� ������ ������
        figure_pos = get(gcf, 'Position'); % x left, y bottom, width, height
        w = figure_pos(3);
        h = figure_pos(4);
        plot_coord = plotboxpos(gca);
        plot_coord([1,3]) = plot_coord([1,3])*w;
        plot_coord([2,4]) = plot_coord([2,4])*h;
        % ��������� ��������� ����
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
       traj_i >= length(trajectory_shift(1,:)) && shift_flag % ����������� ��������
   
        traj_i = 1;
        
        if leg_i < 4 && ~shift_flag
            leg_i = leg_i + 1;  % ������� ��������� ����
        elseif ~shift_flag
            leg_i = 1;
            shift_flag = true;  % ������ �������� ����
        else
            shift_flag = false; % ����� ����� ������� ����
            
            if save_gif_flag
                return
            end
        end
    end
    if ~save_gif_flag
        pause(delay)
    end
end









