#!/bin/bash
# Usage:
# ./k8s_iperf.sh ip-address

ip=$1
iperf_port=$2
sona_env=$3
mkdir -p $HOME/test_files/log/$2
iperf_log_file=$HOME/test_files/log/$(date +%s)_$3_client_to_k8s_svc_iperf_t600_A0-7_w256k_l128k
for i in {1..10};do
	iperf3 -c $1 -p $iperf_port -f k -t 610 -O 10 | tail -4 | head -1 > $iperf_log_file'-'$i'.log'
	sleep 30
done
