#!/bin/bash

test_files='32B 64B 128B 256B 512B 1KB 2KB 4KB 8KB 16KB 32KB 64KB'
target_ip=$1

for e in $test_files;do
	echo "$1/$e" > k8s_curl_test_list/$e
	for i in {1..7};do
		echo "$1/$e" >> k8s_curl_test_list/$e
	done

	echo "Testing filesize: $e"
	results=()
	for n in {1..6};do
		# echo "n=$n"
		results[n]=$(./curl-pN-4k8s.sh k8s_curl_test_list/$e 8)
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
