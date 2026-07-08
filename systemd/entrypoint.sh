#!/bin/bash
set -e

# Write the arguments to the file. 
# "$*" takes all positional parameters and joins them into a single string.
echo "SLURMD_OPTIONS=\"$*\"" > /etc/sysconfig/slurmd

# Execute systemd as PID 1
echo "Arguments captured: $*"
echo "Executing /sbin/init"
exec /sbin/init
