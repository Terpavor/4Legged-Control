clc;
clearvars;
format shortg;
%% Общие данные
f_clk = 16 * 10^6; % Гц, тактовая частота микроконтроллера
F = 50; % Гц, частота обновления положения сервы
T = 1/F; % с, период обновления положения сервы

%% Данные для MS-3.2-36

struct.servo_name = 'MS-3.2-36'; % название

struct.angle = 120; % градусов, максимальный угол

struct.t_min = 900  * 10^-6; % с, длительность импульса, соответствующая 0 градусам
struct.t_max = 2100 * 10^-6; % с, длительность импульса, соответствующая 120 градусам
struct.t_delta = (struct.t_max - struct.t_min); % с, их разница

struct.duty_cycle_min = struct.t_min/T*100; % процентов, минимальная скважность
struct.duty_cycle_max = struct.t_max/T*100; % процентов, максимальная скважность

servo_1a = struct;
servo_1b = struct;
%% Данные для S8166M

struct.servo_name = 'S8166M'; % название

%% Данные для SG-90

struct.servo_name = 'SG-90'; % название

struct.angle = 180; % градусов, максимальный угол

struct.t_min = 1000 * 10^-6; % с, длительность импульса, соответствующая 0 градусам
struct.t_max = 2000 * 10^-6; % с, длительность импульса, соответствующая 180 градусам
struct.t_delta = (struct.t_max - struct.t_min); % с, их разница

struct.duty_cycle_min = struct.t_min/T*100; % процентов, минимальная скважность
struct.duty_cycle_max = struct.t_max/T*100; % процентов, максимальная скважность

servo_3 = struct;
%% Таймер 1 - вариант 1

N = 8; %1, 8, 64, 256, or 1024
TOP = 39999; %(2^8) * (156:1:156)'
R_FPWM = floor( log(TOP) / log(2) )+1; % число используемых битов в таймере
f_OCnxPWM_16 = f_clk ./ (N.*(1+TOP));
T_OCnxPWM_16 = 1 ./ f_OCnxPWM_16;

disp([TOP  T_OCnxPWM_16 f_OCnxPWM_16]);

% Подобрали параметры так, чтобы таймер переполнялся с f = 50 Гц

servo_3.tick_res = TOP * servo_3.t_delta ./ T_OCnxPWM_16; % разрешение сервы в тиках таймера
servo_3.deg_res  = servo_3.angle ./ servo_3.tick_res; % разрешение в градусах

(1+TOP) * 700  * 10^-6 ./ T_OCnxPWM_16
(1+TOP) * 2600  * 10^-6 ./ T_OCnxPWM_16

servo_3.tick_res 
servo_3.deg_res 
return
servo_1a


%% Таймер 1 - вариант 1

N = 8; %1, 8, 64, 256, or 1024
TOP = 39999; %(2^8) * (156:1:156)'
R_FPWM = floor( log(TOP) / log(2) )+1; % число используемых битов в таймере
f_OCnxPWM_16 = f_clk ./ (N.*(1+TOP));
T_OCnxPWM_16 = 1 ./ f_OCnxPWM_16;

%disp([TOP  T_OCnxPWM_16 f_OCnxPWM_16]);

% Подобрали параметры так, чтобы таймер переполнялся с f = 50 Гц

servo_1a.tick_res = TOP * servo_1a.t_delta ./ T_OCnxPWM_16; % разрешение сервы в тиках таймера
servo_1a.deg_res  = servo_1a.angle ./ servo_1a.tick_res; % разрешение в градусах

(1+TOP) * servo_1a.t_min ./ T_OCnxPWM_16
(1+TOP) * servo_1a.t_max ./ T_OCnxPWM_16

servo_1a.tick_res 
servo_1a.deg_res 
return
servo_1a

%% Таймер 1 - вариант 2

N = 1; %1, 8, 64, 256, or 1024
TOP = (2^8) * (156:1:156)';
R_FPWM = floor( log(TOP) / log(2) )+1; % число используемых битов в таймере
f_OCnxPWM_16 = f_clk ./ (N.*(1+TOP));
T_OCnxPWM_16 = 1 ./ f_OCnxPWM_16;

%disp([TOP/256  T_OCnxPWM_16 f_OCnxPWM_16]);

% Подобрали параметры так, чтобы таймер переполнялся с f = 400 Гц
% Теперь в 1-ом периоде из 8-и мы работаем с сервой, а в 7-и других -
% простаиваем.

servo_1b.tick_res = TOP * servo_1b.t_delta ./ T_OCnxPWM_16; % разрешение сервы в тиках таймера
servo_1b.deg_res  = servo_1b.angle ./ servo_1b.tick_res; % разрешение в градусах

servo_1b







% 
% f = 16*10^6 /( 1024*(1+2^16) )
% T = 1/f
% T*256/60
% 
% fprintf('%10.10f\n',T);
% %return
% 
% arr = [1 5 2 4 1 3];
% n = numel(arr);
% arr_order = 1:n;
% 
% while n > 0
%     newn = 0;
%     for i = 2:n
%         if arr(i-1) > arr(i)
%             arr([i-1 i]) = arr([i, i-1]);
%             arr_order([i-1 i]) = arr_order([i, i-1]);
%             newn = i;
%         end
%     end
%     n = newn;
% end
% arr
% arr_order
% 
% %return

