% Matlab R2014b
clc
clear all
close all

addpath('../auxiliary')

save_gif_flag = false;
%%

P = csvread('csv_point_cloud.dat');

x = P(:,1);
z = P(:,3);

%  figure;
%  h = plot(x,z,'.');
% axis equal;
% grid on
% print('1','-dpng');
%%
shp = alphaShape(x,z)%,0.15,'HoleThreshold',15);

% figure;
% axis equal;
% grid on
% plot(shp)
%print('[-45 135][-90 90]','-dpng');
%%
[bf, P] = boundaryFacets(shp);
% замыкаем, хотя polyarea как-то переваривает и разомкнутый полигон
P(end+1,:) = P(1,:);
polyarea(P(:,1),P(:,2))

figure;
plot(P(:,1), P(:,2),'k');
xlabel('x, мм');
ylabel('z, мм');
axis equal;
grid on


print('3','-dpng');





