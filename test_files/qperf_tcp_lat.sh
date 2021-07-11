for i in {1..5};do
	echo "[Test $i]"
	qperf 192.168.60.2 -oo msg_size:32:64K:*2 tcp_lat
done
