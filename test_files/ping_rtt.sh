ip=$1
ping -i 0.5 -c 1000 $ip | grep time | awk '{split($0,a,"time="); print a[2]}' | rev | cut -c 4- | rev