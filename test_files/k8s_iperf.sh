#!/bin/sh
# Usage:
# ./k8s_iperf.sh ip-address

iperf_log_file=/test_files/iperf3_log/$(date +%s)k8s_pod_to_pod_t600_A0-7_w256k_l128k
touch $iperf_log_file
ip=$1
for i in {1..10};do
	iperf3 -c $1 -p 5201 -f k -t 600 -w 512k | tail -4 | head -1 > $iperf_log_file'-'$i'.log'
	sleep 30
	# iperf3 -c $1 -p 5201 -f k -t 10 -w 512k  --logfile $iperf_log_file
done
