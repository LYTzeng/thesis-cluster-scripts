#test_files=("256K" "512K" "1M" "2M" "4M" "8M" "16M" "32M" "64M" "128M" "256M" "512M" "1G")
test_files=("32B" "64B" "128B" "256B" "512B" "1KB" "2KB" "4KB" "8KB" "16KB" "32KB" "64KB")
target_ip=$1

for e in ${test_files[@]};do
	echo "Testing filesize: $e"
	results=()
	result_pair=()
	for n in {1..6};do
		# echo "n=$n"
		result_pair=$(curl -o /dev/null -s -H 'Cache-Control: no-cache' -w "%{time_starttransfer} %{time_total} \n" $target_ip/$e)
		results[n]=$result_pair
	done
	echo "Avg. TTFB"
	for n in {2..6};do
		IFS=', ' read -r -a array <<< ${results[n]}
		echo ${array[0]}
	done
	echo "Avg. JCT"
	for n in {2..6};do
		IFS=', ' read -r -a array <<< ${results[n]}
		echo ${array[1]}
	done
	printf "\n"
done
