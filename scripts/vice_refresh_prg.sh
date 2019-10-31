#!/bin/bash
# 
# vice_refresh_prg.sh - Johan Smet - BSD-3-Clause (see LICENSE)
#
# Monitor the specified PRG-file and reload it in Vice when changes are detected 

if [ $# -ne 1 ]; then
	echo "usage = $0 <prg>"
	exit 1
fi

PRG=$1

# start a VICE instance if necessary
ps -ef | grep "[x]64" | grep "[r]emotemonitor" >> /dev/null 2>&1
if [ $? -ne 0 ]; then
	~/vice/bin/x64 -remotemonitor -autostart $PRG & >> /dev/null 2>&1
fi

inotifywait --quiet --monitor --event modify $PRG | 
	while read; do 
		vice_run_prg.sh $PRG
	done
