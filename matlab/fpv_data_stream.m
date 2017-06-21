% Matlab R2014b
clc
clear all
close all
format shortg;
%%

resolution = 1280*720;
frame_rate = 24;
bits_per_pixel = 8*3;

stream = resolution*frame_rate*bits_per_pixel;

stream_table = ...
[stream    , stream/8            % ���/c     ����/c
stream/2^10, stream/2^10 / 8     % ����/c    �����/c
stream/2^20, stream/2^20 / 8]    % ����/c    �����/c

h264_stream_table = stream_table/100

mjpg_stream_table = stream_table/20