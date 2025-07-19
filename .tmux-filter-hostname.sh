#!/bin/bash
# Filter hostname from tmux window names

input="$1"
hostname=$(hostname)
hostname_short=$(hostname -s)

# If input is exactly the hostname (with or without .local), replace with -
if [[ "$input" == "$hostname" ]] || [[ "$input" == "$hostname_short" ]] || [[ "$input" == "${hostname_short}.local" ]]; then
    echo "-"
else
    echo "$input"
fi