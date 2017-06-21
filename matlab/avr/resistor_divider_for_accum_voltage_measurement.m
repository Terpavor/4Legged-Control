clc;
clearvars;
format shortg;
close all;

%%

U_accum = [3.3 4.2]*3; % В % [мин макс]

R(1) = 220*10^3; % Ом
R(2) = 100*10^3; % Ом

I = U_accum/sum(R); % А
I*10^6 % мкА

U_r2 = U_accum*R(2)/sum(R) % В