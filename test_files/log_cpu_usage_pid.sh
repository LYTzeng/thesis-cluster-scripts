PID=$1
mkdir -p ~/test_files/log
while true;do top -p $PID -b -n1 |tail -1| awk '{print strftime("%Y-%m-%d-%H:%M:%S", systime()), $9}' >> ~/test_files/log/cpu_usage.log;sleep 3;done
