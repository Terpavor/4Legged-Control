% Matlab R2014b
clc
clear all
close all
addpath('./auxiliary')
addpath('./kinematics')
addpath('./cyclogram')
addpath('./static_walk')
addpath('./work_zone')

save_gif_flag = false;
    gif_delay = 1/20; % �
    first_frame_flag = true;
    gif_filename = 'static_walk2.gif';

colored_plot_flag = true;

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
leg(1).pos = [-x_shift +y_shift z_shift]';
leg(2).pos = [+x_shift +y_shift z_shift]';
leg(3).pos = [+x_shift -y_shift z_shift]';
leg(4).pos = [-x_shift -y_shift z_shift]';

% ��� ������ �������(������������) ��������� ����������
leg(1).sign = +1;
leg(2).sign = -1;
leg(3).sign = -1;
leg(4).sign = +1;

point_1 = [-0.3 0 ground_height]'; % ��������� ����� ���� � �� ������
point_2 = [+0.3 0 ground_height]'; % �������� ����� ���� � �� ������

% ����, ����������, ��� � ������� ���� �������� ���� �������� ���� ������
shift_flag = false;

traj_point_count = 20;

trajectory_step = cyclogram_make_one_step( point_1, point_2, traj_point_count );
trajectory_shift = cyclogram_CoM_shift( point_2, point_1, traj_point_count );

% ����� ��������� ���������
for i=1:leg_count;
    g{i} = trajectory_step(1:3,1);
    [leg(i).angles,~] = inverse_kinematics(g{i}, +1);    
    
    R{i} = forward_kinematics(leg(i).angles); % ��������� ������� ��� �������� �����
    R{i} = R{i} + repmat(leg(i).pos, [1 4]); % �� ���� -> �� ������
end

trajectory = static_walk(R, g, [1 0 0], ground_height, traj_point_count);


%% �����������
% ����
hFig = figure('Position', [50, 50, 1000, 800]);

% ������
if ~colored_plot_flag
    hPlot(1) = plot3(0, 0, 0, ...       % ���� 1
                     'Color', 'k', 'LineWidth', 1, ...
                     'Marker', '.', 'MarkerSize', 15, 'MarkerEdgeColor', 'k');
    hPlot(2) = copyobj(hPlot(1),gca);   % ���� 2 
    hPlot(3) = copyobj(hPlot(1),gca);   % ���� 3
    hPlot(4) = copyobj(hPlot(1),gca);   % ���� 4
    hPlot(5) = copyobj(hPlot(1),gca);   % �������������� �������������
    hPlot(6) = copyobj(hPlot(1),gca);   % �������� ������ ������� �� "�����"
    hPlot(7) = copyobj(hPlot(1),gca);   % ������
    set( hPlot(5),   'Color', 'k', 'LineWidth', 0.5, ...
                     'Marker', 'o', 'MarkerSize', 6, 'MarkerEdgeColor', 'k');
    set( hPlot(6),  'XData',0, 'YData',0, 'ZData',ground_height, ...
                    'MarkerEdgeColor', 'k', 'Marker', '.', 'MarkerSize', 15 );
else
    hPlot(1) = plot3(0, 0, 0, ...       % ���� 1
                     'Color', 'c', 'LineWidth', 1, ...
                     'Marker', '.', 'MarkerSize', 15, 'MarkerEdgeColor', 'g');
    hPlot(2) = copyobj(hPlot(1),gca);   % ���� 2 
    hPlot(3) = copyobj(hPlot(1),gca);   % ���� 3
    hPlot(4) = copyobj(hPlot(1),gca);   % ���� 4
    hPlot(5) = copyobj(hPlot(1),gca);   % �������������� �������������
    hPlot(6) = copyobj(hPlot(1),gca);   % �������� ������ ������� �� "�����"
    hPlot(7) = copyobj(hPlot(1),gca);   % ������
    set( hPlot(5),   'Color', 'g', 'LineWidth', 0.5, ...
                     'Marker', 'o', 'MarkerSize', 6, 'MarkerEdgeColor', 'r');
    set( hPlot(6),  'XData',0, 'YData',0, 'ZData',ground_height, ...
                    'MarkerEdgeColor', 'b', 'Marker', '.', 'MarkerSize', 15 );
end
robot_case = [  leg(1).pos, leg(2).pos, leg(3).pos, leg(4).pos leg(1).pos];
set( hPlot(7),  'XData',robot_case(1,:), ...
                'YData',robot_case(2,:), ...
                'ZData',robot_case(3,:) );
% copyobj ��� ������ "hold on" ��� plot3

hold off
axis equal;
% axis_limits = [ -sum(L(2:end))-x_shift	sum(L(2:end))+x_shift ...
%                 -sum(L)-y_shift         sum(L)+y_shift ...
%                 ground_height           sum(L)];
axis_limits = [ -sum(L(2:end))-0.4	sum(L(2:end))+0.4 ...
                -sum(L)+0.5         sum(L)-0.5 ...
                ground_height           0.5];
axis(axis_limits);

grid on
xlabel('x');
ylabel('y');
zlabel('z');
campos([-0.6 -1 0.1]);
drawAxes(3, [0 0 0 0.3], {'x', 'y', 'z'});


% ������� ���
for i=1:leg_count
    hText(i) = text(leg(i).pos(1), leg(i).pos(2), leg(i).pos(3), num2str(i));
end

%% ��������
% ��������� ��������
frame_frequency = 50; % ������ � �������
if save_gif_flag
    delay = 0;
else
    delay = 1/frame_frequency; % ������
end

%imageData = screencapture(gca); % select a small axes region
%imwrite(imageData, strcat(0,'.png')); % display the captured image in a matlab figure


traj_i = 1; % ����� ����� ����������
phase_i = 1; % ����� ����(���������������� ��� ������ ������ static_walk.m)
while ishandle(hFig)
    
    for i=1:leg_count;
        g{i} = trajectory{i}(traj_i,:)';
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
        supporting_polygon = get_supporting_polygon(R, ground_height);
        % �������� �����
        supporting_polygon = [supporting_polygon, supporting_polygon(:,1)];
        
        set( hPlot(5),  'XData',supporting_polygon(1,:), ...
                        'YData',supporting_polygon(2,:), ...
                        'ZData',supporting_polygon(3,:) );
    % ������������� ������������ ������ ��� pause
        drawnow;
    % ������� � ������� ���������� � ����
        clc;
        phase_i
        fprintf(  '�����(\t x,\t\t y,\t\t z\t ), �����(���) ����\n');
        fprintf(  '�%1.d\t (%6.3f, %6.3f, %6.3f ), %3.f�(%3.f�)\n', ...
                        cat(1, 1:4, R{1}(1:3,1:4), [rad2deg(wrapTo2Pi(Phi')) NaN ], ...
                        rad2deg( wrapToPi([Phi(1), cumsum(Phi(2:end))', NaN]) ) ) );
    
    
    if save_gif_flag
        if phase_i > 9 % ����� �������� ������ ���� �����
            % �������� ���������� ������� � ��������, ��� ������ ������
            figure_pos = get(gcf, 'Position'); % x left, y bottom, width, height
            w = figure_pos(3)+150;
            h = figure_pos(4)+500;
            plot_coord = plotboxpos(gca);
            plot_coord([1]) = plot_coord([1])*550;
            plot_coord([2]) = plot_coord([2])*250;
            plot_coord([3]) = plot_coord([3])*w;
            plot_coord([4]) = plot_coord([4])*h;
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
        if phase_i > 17 % ����� ����������� ������ ����
            return
        end
    end







                    
    traj_i = traj_i+1;
    if traj_i >= length(trajectory{1})
        
        traj_i = 1;
        e = g;
        trajectory = static_walk(R, e, [0.3 0 0], ground_height, traj_point_count);
        phase_i = phase_i+1;
        
        
        %imageData = screencapture(gca); % select a small axes region
        %imwrite(imageData, strcat(num2str(phase_i),'.png')); % display the captured image in a matlab figure
        
        if save_gif_flag && phase_i > 9
            return
        end
        %pause(0.5);
    end
    
    pause(delay);
end









