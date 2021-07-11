mkdir -p ~/iperf3_log/
extra_args=$2
iperf_log_file=~/iperf3_log/$(date +%s)baremetal$2_t600_A0-7_w256k_l128k
for i in {1..10};do
	iperf3 -c $1 -p 5201 -f k -t 610 -O 10 | tail -4 | head -1 > $iperf_log_file'-'$i'.log'
	sleep 30
done
