#!/bin/bash
# Usage:
# ./k8s_iperf.sh ip-address

ip=$1
sona_env=$2
mkdir -p $HOME/test_files/log/$2
iperf_log_file=$HOME/test_files/log/$2/$(date +%s)client_to_k8s_svc_iperf_t600_A0-7_w256k_l128k
for i in {1..10};do
	iperf3 -c $1 -p 5201 -f k -t 610 -O 10 | tail -4 | head -1 > $iperf_log_file'-'$i'.log'
	sleep 30
	# iperf3 -c $1 -p 5201 -f k -t 10 -w 512k  --logfile $iperf_log_file
done
