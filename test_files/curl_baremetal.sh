curl -o /dev/null -H 'Cache-Control: no-cache' -w "Connect: %{time_connect} TTFB: %{time_starttransfer} JCT: %{time_total} Pretransfer: %{time_pretransfer} \n" 192.168.60.2
