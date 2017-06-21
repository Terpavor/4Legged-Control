#!/bin/bash 
 
DISPLAY="1" # display number
GEOMETRY="1280x800"
DEPTH="24" # bits

echo "vnc"
case "$1" in
	start)
		echo "started"
		vncserver :$DISPLAY -geometry $GEOMETRY -depth $DEPTH
		# if it's already running we'll get "A VNC server is already running as :1"
		;;
	stop)
		echo "stopped"
		vncserver -kill :$DISPLAY
		;;
	restart)
		echo "restarted"
		$0 stop
		$0 start
		;;
esac

exit 0