#!/bin/bash
# Fixed for your specific interface: enp4s0

INTERFACE="enp4s0"

echo "--- WhatPulse Hardware Comparison ---"
echo "Interface: $INTERFACE | Monitoring: 15s"
echo "--------------------------------------"

# Capture physical traffic only
sudo stdbuf -oL -eL nethogs -t -c 15 $INTERFACE | awk '
  # Matches lines with a process path
  /\// { 
    app=$1; sent=$2; received=$3;
    total_sent[app] += sent;
    total_recv[app] += received;
  }
  END {
    printf "%-35s | %-12s | %-12s\n", "PROCESS", "SENT (KB)", "RECV (KB)"
    print "-------------------------------------------------------------------"
    for (a in total_sent) {
        if (total_sent[a] > 0.5 || total_recv[a] > 0.5)
            printf "%-35s | %-12.2f | %-12.2f\n", a, total_sent[a], total_recv[a]
    }
  }'