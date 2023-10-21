#!/bin/sh	
#	
# /etc/rc.d/ly start/stop Ly Display Manager	
#	

. /etc/rc.subr

PROG=/usr/bin/ly
PIDFILE=/run/ly.pid
CONFTTY=$(cat /etc/ly/config.ini | sed -n 's/^tty.*=[^1-9]*// p')
TTY="tty${CONFTTY:-1}"
TERM=linux
OPTS="$TTY $TERM"
	
case $1 in	
	start)	
		msg "Starting Ly Display Manager..."	
		start_daemon $PROG $OPTS
		;;	
	stop)	
		msg "Stopping Ly Display Manager..."	
		stop_daemon $PROG
		;;	
	restart)	
		$0 stop	
		sleep 1	
		$0 start	
		;;	
	status)	
		status_daemon $PROG
		;;	
	*)	
		echo "Usage: $0 [start|stop|restart|status]"	
		;;	
esac

# End of file
