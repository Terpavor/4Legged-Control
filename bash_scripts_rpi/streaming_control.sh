#!/bin/bash

sudo modprobe bcm2835-v4l2


PORT="8554" # it's default value
FRAMERATE="25"
FRAME_QUEUE="1" # min value
WIDTH="1280"
HEIGHT="720"

v4l2rtspserver -P $PORT -F $FRAMERATE -Q $FRAME_QUEUE -W $WIDTH -H $HEIGHT
