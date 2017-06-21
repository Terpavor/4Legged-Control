clc;
clearvars;
format shortg;
%% Общие данные
f_clk = 16 * 10^6; % Гц, тактовая частота микроконтроллера
F = 50; % Гц, частота обновления положения сервы
T = 1/F; % с, период обновления положения сервы

%% Данные АЦП

prescaler_values = [2, 2.^(1:7)]'; % 2 2 4 8 16 32 64 128

conversion_time = 13.5; % циклов % режим: Auto Triggered conversions

channel_count = 12; % каналов АЦП

sample_count = 1;

time_range = (2500/40000) * 20*10^-3; %

f_adc = f_clk./prescaler_values./conversion_time
T_adc = 1./f_adc

T_adc_total = T_adc*channel_count*sample_count;

[prescaler_values T_adc_total T_adc_total<time_range]

1./T_adc_total*channel_count


x = de2bi(32:39, 'left-msb');

de2bi(8, 'left-msb')
[(32:39)' x]