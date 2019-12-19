#!/bin/bash

# Update the OS.
yum update -y

# Display the log files from
# priority levels 0 (emergency) to 2 (emergency).
journalctl -p "emerg".."crit"
