#!/bin/bash
# 
# vice_run_prg.sh - Johan Smet - BSD-3-Clause (see LICENSE)
#
# Use the remote monitor feature of Vice to run the PRG-file specified in $1
#	Vice has to be configured to enable the remote monitor (e.g. start using -remotemonitor param)

if [ $# -ne 1 ]; then
	echo "usage = $0 <prg>"
	exit 1
fi

PRG=`readlink -f $1`
VICE_HOST=localhost
VICE_PORT=6510

function send_monitor {
	echo $1 | ncat $VICE_HOST $VICE_PORT >> /dev/null
}

send_monitor 'reset 0'					# soft reset the C64
sleep 1									# wait until reset is done
send_monitor "l \"$PRG\" 0"				# load the binary
sleep 1									# wait until reset is done
send_monitor 'g $801'					# jump to the std Basic entrypoint
send_monitor "keybuf \x52\x55\x4e\x0d"	# fake typing "RUN" + enter

