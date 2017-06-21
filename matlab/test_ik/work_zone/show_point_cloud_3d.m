% Matlab R2014b
clc
clear all
close all

addpath('../auxiliary')

save_gif_flag = false;
%%

P = csvread('csv_point_cloud.dat');
size(P)

x = P(:,1);
y = P(:,2);
z = P(:,3);

figure;
h = plot3(x,y,z,'.');
axis equal;
grid on
xlabel('x');
ylabel('y');
zlabel('z');

print('1','-dpng');
%%
shp = alphaShape(x,y,z,0.15,'HoleThreshold',15);

figure;
axis equal;
grid on
plot(shp)
xlabel('x');
ylabel('y');
zlabel('z');

print('2','-dpng');
%%
[bf, P] = boundaryFacets(shp);

figure;
trisurf(bf, P(:,1), P(:,2), P(:,3));
axis equal;
grid on
xlabel('x');
ylabel('y');
zlabel('z');

print('3','-dpng');















print('3','-dpng');