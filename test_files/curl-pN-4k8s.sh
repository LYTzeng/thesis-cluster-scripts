
#!/bin/bash

tmpFile=`echo "$(basename $0 .sh)"`
if [ $# -ne 2 ]
then
    echo "Syntax: $0 file-with-urls num-of-parallel-curls"
        echo "Example: $0 curl-pN.sh GET-PNG-ALL.dat 100";
    exit
fi



URL_DAT_FILE=$1
P_RUN=$2

output=$(cat $URL_DAT_FILE | xargs -n1 -P$P_RUN curl -o /dev/null -s -H 'Cache-Control: no-cache' -w "%{time_starttransfer},%{time_total};")

threads=()
ttfb=()
jct=()
for i in {1..8};do
	threads[$i]=$(echo $output | cut -f "$i" -d \;)
done

for i in ${!threads[@]};do
	ttfb[$i]=$(echo ${threads[$i]} | cut -f1 -d \,)
	jct[$i]=$(echo ${threads[$i]} | cut -f2 -d \,)
done

ttfb_sum=$(awk 'BEGIN {t=0; for (i in ARGV) t+=ARGV[i]; print t}' "${ttfb[@]}")
jct_sum=$(awk 'BEGIN {t=0; for (i in ARGV) t+=ARGV[i]; print t}' "${jct[@]}")

ttfb_avg=$(awk "BEGIN {print $ttfb_sum / 8}")
jct_avg=$(awk "BEGIN {print $jct_sum / 8}")
# echo "Average TTFB: $ttfb_avg"
# echo "Average JCT $jct_avg"
echo "$ttfb_avg $jct_avg"