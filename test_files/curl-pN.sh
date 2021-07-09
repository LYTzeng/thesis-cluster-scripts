
#!/bin/bash
#by rvilker@synamedia.com
#trap read debug
#set -x

tmpFile=`echo "$(basename $0 .sh)"`
if [ $# -ne 2 ]
then
    echo "Syntax: $0 file-with-urls num-of-parallel-curls"
        echo "Example: $0 curl-pN.sh GET-PNG-ALL.dat 100";
    exit
fi



URL_DAT_FILE=$1
P_RUN=$2

output=$(cat $URL_DAT_FILE | xargs -L1 -P$P_RUN curl -o /dev/null -s -w "%{time_starttransfer},%{time_total};")

declare -A threads
declare -A ttfb
declare -A jct
for i in {1..8};do
	threads[$i]=$(echo $output | cut -f "$i" -d \;)
done

for i in ${!threads[@]};do
	ttfb[$i]=$(echo ${threads[$i]} | cut -f1 -d \,)
	jct[$i]=$(echo ${threads[$i]} | cut -f2 -d \,)
done

ttfb_sum=$( IFS="+";bc <<< "${ttfb[*]}" )
jct_sum=$( IFS="+";bc <<< "${jct[*]}" )

ttfb_avg=$( bc <<< "scale=8; $ttfb_sum / 8" )
jct_avg=$( bc <<< "scale=8; $jct_sum / 8" )
# echo "Average TTFB: $ttfb_avg"
# echo "Average JCT $jct_avg"
echo "$ttfb_avg $jct_avg"