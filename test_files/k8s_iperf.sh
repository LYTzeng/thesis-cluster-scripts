# iperf_log_file=~/iperf3_log/$(date +%s)baremetal_t600_A0-7_w256k_l128k.log
# touch $iperf_log_file
ip=$1
for i in {1..10};do
	iperf3 -c $1 -p 5201 -f k -t 600 -w 512k | tail -4 | head -1
	# iperf3 -c 192.168.60.3 -p 5201 -f k -t 10 -w 512k  #--logfile $iperf_log_file
done
