clc;
clearvars;
format shortg;
close all;

%%

U_accum = [3.3 4.2]*3; % � % [��� ����]

R(1) = 220*10^3; % ��
R(2) = 100*10^3; % ��

I = U_accum/sum(R); % �
I*10^6 % ���

U_r2 = U_accum*R(2)/sum(R) % �