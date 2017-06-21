clc;
clearvars;
format shortg;
%% ����� ������
f_clk = 16 * 10^6; % ��, �������� ������� ����������������
F = 50; % ��, ������� ���������� ��������� �����
T = 1/F; % �, ������ ���������� ��������� �����

%% ������ ��� MS-3.2-36

struct.servo_name = 'MS-3.2-36'; % ��������

struct.angle = 120; % ��������, ������������ ����

struct.t_min = 900  * 10^-6; % �, ������������ ��������, ��������������� 0 ��������
struct.t_max = 2100 * 10^-6; % �, ������������ ��������, ��������������� 120 ��������
struct.t_delta = (struct.t_max - struct.t_min); % �, �� �������

struct.duty_cycle_min = struct.t_min/T*100; % ���������, ����������� ����������
struct.duty_cycle_max = struct.t_max/T*100; % ���������, ������������ ����������

servo_1a = struct;
servo_1b = struct;
%% ������ ��� S8166M

struct.servo_name = 'S8166M'; % ��������

%% ������ ��� SG-90

struct.servo_name = 'SG-90'; % ��������

struct.angle = 180; % ��������, ������������ ����

struct.t_min = 1000 * 10^-6; % �, ������������ ��������, ��������������� 0 ��������
struct.t_max = 2000 * 10^-6; % �, ������������ ��������, ��������������� 180 ��������
struct.t_delta = (struct.t_max - struct.t_min); % �, �� �������

struct.duty_cycle_min = struct.t_min/T*100; % ���������, ����������� ����������
struct.duty_cycle_max = struct.t_max/T*100; % ���������, ������������ ����������

servo_3 = struct;
%% ������ 1 - ������� 1

N = 8; %1, 8, 64, 256, or 1024
TOP = 39999; %(2^8) * (156:1:156)'
R_FPWM = floor( log(TOP) / log(2) )+1; % ����� ������������ ����� � �������
f_OCnxPWM_16 = f_clk ./ (N.*(1+TOP));
T_OCnxPWM_16 = 1 ./ f_OCnxPWM_16;

disp([TOP  T_OCnxPWM_16 f_OCnxPWM_16]);

% ��������� ��������� ���, ����� ������ ������������ � f = 50 ��

servo_3.tick_res = TOP * servo_3.t_delta ./ T_OCnxPWM_16; % ���������� ����� � ����� �������
servo_3.deg_res  = servo_3.angle ./ servo_3.tick_res; % ���������� � ��������

(1+TOP) * 700  * 10^-6 ./ T_OCnxPWM_16
(1+TOP) * 2600  * 10^-6 ./ T_OCnxPWM_16

servo_3.tick_res 
servo_3.deg_res 
return
servo_1a


%% ������ 1 - ������� 1

N = 8; %1, 8, 64, 256, or 1024
TOP = 39999; %(2^8) * (156:1:156)'
R_FPWM = floor( log(TOP) / log(2) )+1; % ����� ������������ ����� � �������
f_OCnxPWM_16 = f_clk ./ (N.*(1+TOP));
T_OCnxPWM_16 = 1 ./ f_OCnxPWM_16;

%disp([TOP  T_OCnxPWM_16 f_OCnxPWM_16]);

% ��������� ��������� ���, ����� ������ ������������ � f = 50 ��

servo_1a.tick_res = TOP * servo_1a.t_delta ./ T_OCnxPWM_16; % ���������� ����� � ����� �������
servo_1a.deg_res  = servo_1a.angle ./ servo_1a.tick_res; % ���������� � ��������

(1+TOP) * servo_1a.t_min ./ T_OCnxPWM_16
(1+TOP) * servo_1a.t_max ./ T_OCnxPWM_16

servo_1a.tick_res 
servo_1a.deg_res 
return
servo_1a

%% ������ 1 - ������� 2

N = 1; %1, 8, 64, 256, or 1024
TOP = (2^8) * (156:1:156)';
R_FPWM = floor( log(TOP) / log(2) )+1; % ����� ������������ ����� � �������
f_OCnxPWM_16 = f_clk ./ (N.*(1+TOP));
T_OCnxPWM_16 = 1 ./ f_OCnxPWM_16;

%disp([TOP/256  T_OCnxPWM_16 f_OCnxPWM_16]);

% ��������� ��������� ���, ����� ������ ������������ � f = 400 ��
% ������ � 1-�� ������� �� 8-� �� �������� � ������, � � 7-� ������ -
% �����������.

servo_1b.tick_res = TOP * servo_1b.t_delta ./ T_OCnxPWM_16; % ���������� ����� � ����� �������
servo_1b.deg_res  = servo_1b.angle ./ servo_1b.tick_res; % ���������� � ��������

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

