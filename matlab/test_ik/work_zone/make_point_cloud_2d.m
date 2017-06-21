% Matlab R2014b
clc
clear all
close all

show_animation = false;
point_count = 75;
%% ����:
global L

L(1) = 68.2;
L(2) = 97.8;
L(3) = 143;

Phi = zeros(2,1);

Phi_min = [0 -90            -30];
Phi_max = [0 Phi_min(2)+180 Phi_min(3)+180];



%% �����������
% ����
if show_animation
    
    R = fk_rrr(Phi);
    
    hFig = figure('Position', [50, 50, 1000, 800], 'Color',[1 1 1]);

    % ������
    hPlot = plot(R(1,:), R(2,:),'-x');
    axis equal;
    axis(  [-sum(L)	sum(L) ...
            -sum(L)	sum(L)]);
    grid on
    xlabel('x');
    ylabel('y');
end

%% ������ ����� � �����(="���������� �����������")
range{1} = linspace(deg2rad(Phi_min(2)),deg2rad(Phi_max(2)),point_count);
range{2} = linspace(deg2rad(Phi_min(3)),deg2rad(Phi_max(3)),point_count);
[Phi2,Phi3] = meshgrid(range{1},range{2});

Phi1 = zeros(size(Phi2));
point_cloud_in = [Phi1(:) Phi2(:) Phi3(:)];
point_cloud_out = zeros(length(point_cloud_in), 3);

%% ��������

fprintf('start\n'); 
for i=1:length(point_cloud_in)
    % ����� ����� �����
    Phi = point_cloud_in(i,:)';
    
    % ��������� ����� ��������� ������(x1-4,y1-4)
    R = fk_rrr(Phi);
    % ����� ������(x4,y4)
    point_cloud_out(i,:) = R(1:3,end)';
    
    % ��������� ������
    if show_animation
        set(hPlot, 'XData',R(1,:), 'YData',R(2,:));
        % ������������� ������������ ������ ��� pause
        drawnow;
    end
end
fprintf('saving...\n'); 

point_cloud_out = unique(point_cloud_out,'rows'); % �� �����������
csvwrite('csv_point_cloud.dat',point_cloud_out);

fprintf('end\n')
