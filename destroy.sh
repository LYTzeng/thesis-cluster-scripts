WORKER1_IP="172.16.0.2"
WORKER2_IP="172.16.0.3"
WORKER1_MGMT_IP="172.30.0.52"
WORKER2_MGMT_IP="172.30.0.53"
EXT_OVS_MGMT_IP="172.30.0.54"

RED='\033[0;31m'
MAGENTA='\u001b[35m'
GREEN='\033[1;32m'
NC='\033[0m'
YELLOW='\033[1;33m'

KUBEADM_RESET="sudo kubeadm reset -f"
CLEAR_IPTABLES="sudo iptables -F ; sudo iptables -t nat -F ; sudo iptables -t mangle -F ; sudo iptables -X"
FLUSH_ROUTE="sudo ip route flush table main && sudo systemctl restart networking"
RM_KUBECONFIG="rm -rf /home/oscar/.kube && sudo rm -rf /root/.kube"
DEL_BR="sudo ovs-vsctl del-br br-int ; sudo ovs-vsctl del-br br-local; sudo ovs-vsctl del-br kbr-local;sudo ovs-vsctl del-br kbr-ex;sudo ovs-vsctl del-br kbr-int"
DEL_CNI="sudo rm /etc/cni/net.d/1-sona-net.conf"
EXEC_ALL="${KUBEADM_RESET} ; ${CLEAR_IPTABLES} ; ${RM_KUBECONFIG} ; ${DEL_BR} ; ${FLUSH_ROUTE} ; ${DEL_CNI}"

print_suc () {
    out=$( echo $1 | awk '{ gsub("-"," ",$1); print $1 }' )
    printf "\r$out ... ${GREEN}[Success]${NC} 🎉🎉\n"
}
print_fail () {
    printf "\r$1 ... ${MAGENTA}[Fail]${NC} 💥💣💥\n"
    args=("$@") 
    ELEMENTS=${#args[@]}
    for (( i=2;i<$ELEMENTS;i++)); do 
        echo -ne "${MAGENTA}${args[${i}]} "
    done
    echo -n "${NC}\n"
    return 127
}
suc_or_fail () {
    if [[ $? -eq 0 || -z ${stderr} ]]; then
        print_suc $1
    else
        print_fail $@
    fi
}

echo -n "reset worker1 ..."
stderr=$(ssh -i ~/.ssh/worker1 oscar@$WORKER1_MGMT_IP "eval $EXEC_ALL" 2>&1 > /dev/null)
suc_or_fail "reset-worker1" $stderr
echo -n "reset worker2 ..."
stderr=$(ssh -i ~/.ssh/worker2 oscar@$WORKER2_MGMT_IP "eval $EXEC_ALL" 2>&1 > /dev/null)
suc_or_fail "reset-worker2" $stderr
echo -n "reset master ..."
stderr=$(eval $EXEC_ALL 2>&1 > /dev/null)
suc_or_fail "reset-master" $stderr

RECREATE_BR="sudo ovs-vsctl add-br kbr-int; sudo ovs-vsctl add-br kbr-ex"
EXEC_ALL="${DEL_BR} ; ${RECREATE_BR} ; ${FLUSH_ROUTE}"
echo -n "reset external ovs ..."
stderr=$(ssh oscar@$EXT_OVS_MGMT_IP "eval $EXEC_ALL" 2>&1 > /dev/null)
suc_or_fail "reset-external-ovs" $stderr
