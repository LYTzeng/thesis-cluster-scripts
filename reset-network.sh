WORKER1_IP="172.16.0.2"
WORKER2_IP="172.16.0.3"
WORKER1_MGMT_IP="172.30.0.241"
WORKER2_MGMT_IP="172.30.0.242"
EXT_OVS_MGMT_IP="172.30.0.243"

DEL_BR="sudo ovs-vsctl del-br br-int ; sudo ovs-vsctl del-br br-local; sudo ovs-vsctl del-br kbr-local;sudo ovs-vsctl del-br kbr-ex;sudo ovs-vsctl del-br kbr-int"
RESTART_NET='sudo systemctl restart networking'
EXEC_ALL="${DEL_BR} ; ${RESTART_NET}"

print_suc () {
    out=$( echo $1 | awk '{ gsub("-"," ",$1); print $1 }' )
    printf "\r$out ... ${GREEN}[Success]${NC} 🎉🎉\n"
}
print_fail () {
    out=$( echo $1 | awk '{ gsub("-"," ",$1); print $1 }' )
    printf "\r$out ... ${MAGENTA}[Fail]${NC} 💥💣💥\n"
    args=("$@") 
    ELEMENTS=${#args[@]}
    for (( i=1;i<$ELEMENTS;i++)); do 
        echo -ne "${MAGENTA}${args[${i}]} "
    done
    echo -ne "${NC}\n"
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

RECREATE_BR="sudo ovs-vsctl add-br kbr-int; sudo ovs-vsctl add-br kbr-ex ;\
sudo ovs-vsctl add-port kbr-int eth1;\
sudo ovs-vsctl add-port kbr-int eth2;\
sudo ovs-vsctl add-port kbr-int eth3;\
sudo ovs-vsctl add-port kbr-ex eth4;\
sudo ovs-vsctl add-port kbr-ex eth5;\
sudo ovs-vsctl add-port kbr-ex eth6;\
sudo ovs-vsctl add-port kbr-ex eth7"
RESTART_NETWORKING="sudo systemctl restart networking"
EXEC_ALL="${DEL_BR} ; ${RECREATE_BR} ; ${RESTART_NETWORKING}"
echo -n "reset external ovs ..."
stderr=$(ssh oscar@$EXT_OVS_MGMT_IP "eval $EXEC_ALL" 2>&1 > /dev/null)
suc_or_fail "reset-external-ovs" $stderr
