#!/bin/bash
# Usage:
# ./k8s_iperf.sh ip-address

iperf_log_file=/test_files/log/$(date +%s)k8s_pod_to_pod_iperf$2_t600_A0-7_w256k_l128k
ip=$1
udp=$2
for i in {1..10};do
	iperf3 -c $1 $2 -p 5201 -f k -t 610 -O 10 | tail -4 | head -1 > $iperf_log_file'-'$i'.log'
	sleep 30
	# iperf3 -c $1 -p 5201 -f k -t 10 -w 512k  --logfile $iperf_log_file
done
