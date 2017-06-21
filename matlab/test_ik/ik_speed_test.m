% Matlab R2014b
clc
clear all
close all
addpath('./auxiliary')
addpath('./kinematics')
addpath('./cyclogram')

show_animation = false;
%% ����:
global L

L(1) = 0.2;
L(2) = 0.6;
L(3) = 0.5;

Phi = zeros(3,1);

%% ��������� �������
if show_animation

    g = [0 0 -1]';
    [Phi,~] = inverse_kinematics(g, -1);
    R = forward_kinematics(Phi);
    
    % ����
    hFig = figure('Position', [50, 50, 1000, 800]);

    % ������
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

    % ������� ������
    for i=1:4
        hText(i) = text(R(1,i), R(2,i), R(3,i),num2str(i));
    end

    % ��������� ����� ����������
    nPoints = 40; % ����������
    iPoints = 1; % ����� ��������� �����
    for i=1:nPoints
        hPoint(i) = text(g(1), g(2), g(3), '.', 'Color', 'magenta');
    end
end

%% ��������� �����
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

%% ����

test_count = 4;
time = zeros(1, test_count);

fprintf('start\n'); 
for test_i = 1:test_count
    for i=1:length(trajectory)
        % �������� ��������� ����� ����������
        g = trajectory(:,i);
        tic; % - �������� �����
        % ��������� ����
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
        time(test_i) = time(test_i)+toc; % - ���������� �����
        
        if show_animation
            if ~ishandle(hFig) % ���� ���� �������
                return;
            end
            % ��������� ����� ��������� ������
            R = forward_kinematics(Phi);
            % ��������� ������
            set(hPlot, 'XData',R(1,:), 'YData',R(2,:), 'ZData', R(3,:));
            % ��������� ������� ������
            for j=1:4
                set(hText(j), 'Position', [R(1,j), R(2,j), R(3,j)]);
            end
            % ��������� ����������
            %set(hPoint(iPoints),'Position', [g(1), g(2), g(3)]); % ��������� ����������
            set(hPoint(iPoints),'Position', [R(1,4), R(2,4), R(3,4)]); % �������� ����������
            iPoints = mod(iPoints, nPoints) + 1;        
            % ������������� ������������ ������ ��� pause
            drawnow;
        end
    end
    fprintf('test %d passed. time = %f s\n', test_i, time(test_i));
end
fprintf('end\n');  