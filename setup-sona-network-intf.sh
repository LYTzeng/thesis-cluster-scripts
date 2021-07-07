#!/bin/bash
CLUSTER_SCRIPTS_PATH="/home/`whoami`/cluster-scripts"
WORKER1_MGMT_IP="172.30.0.52"
WORKER2_MGMT_IP="172.30.0.53"

RED='\033[0;31m'
MAGENTA='\u001b[35m'
GREEN='\033[1;32m'
NC='\033[0m'
YELLOW='\033[1;33m'

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


CERATE_KBR_INT_MGMT="sudo ovs-vsctl add-port kbr-int kbr-int-mgmt tag=10 -- set Interface type=internal"
ssh -i ~/.ssh/worker1 oscar@$WORKER1_MGMT_IP "eval $CERATE_KBR_INT_MGMT" 2>&1 > /dev/null
ssh -i ~/.ssh/worker2 oscar@$WORKER2_MGMT_IP "eval $CERATE_KBR_INT_MGMT" 2>&1 > /dev/null

GET_ETH1_IP=$CLUSTER_SCRIPTS_PATH"/show-ip.sh |grep eth1|awk '{split(\$0,a,\" \"); print a[2]}'"

WORKER1_ETH1_IP=$(ssh -i ~/.ssh/worker1 oscar@$WORKER1_MGMT_IP "eval $GET_ETH1_IP")
WORKER2_ETH1_IP=$(ssh -i ~/.ssh/worker2 oscar@$WORKER2_MGMT_IP "eval $GET_ETH1_IP")
MASTER_ETH1_IP=$(eval $GET_ETH1_IP)

SET_LINK_UP="sudo ip l set up dev kbr-int;sudo ip l set up dev kbr-ex;sudo ip l set up dev kbr-local;sudo ip l set up dev kbr-int-mgmt"
ADD_MGMT_VLAN_PORT="sudo ovs-vsctl add-port kbr-int kbr-int-mgmt"

SET_MGMT_VLAN_INTF="sudo ip a del $WORKER1_ETH1_IP dev eth1 && sudo ip a add $WORKER1_ETH1_IP dev kbr-int-mgmt"
EXEC="${SET_LINK_UP};${ADD_MGMT_VLAN_PORT};${SET_MGMT_VLAN_INTF}"
ssh -i ~/.ssh/worker1 oscar@$WORKER1_MGMT_IP "eval $EXEC" 2>&1 > /dev/null

SET_MGMT_VLAN_INTF="sudo ip a del $WORKER2_ETH1_IP dev eth1 && sudo ip a add $WORKER2_ETH1_IP dev kbr-int-mgmt"
EXEC="${SET_LINK_UP};${ADD_MGMT_VLAN_PORT};${SET_MGMT_VLAN_INTF}"
ssh -i ~/.ssh/worker2 oscar@$WORKER2_MGMT_IP "eval $EXEC" 2>&1 > /dev/null

SET_MGMT_VLAN_INTF="sudo ip a del $MASTER_ETH1_IP dev eth1 && sudo ip a add $MASTER_ETH1_IP dev kbr-int-mgmt"
EXEC="${SET_LINK_UP};${ADD_MGMT_VLAN_PORT};${SET_MGMT_VLAN_INTF}"
eval $EXEC


MASTER_POD_PREFIX=$(kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}' | awk '{split($0,a," "); print a[1]}' | awk '{split($0,a,"."); print a[1]"."a[2]}"."a[3]')
WORKER1_POD_PREFIX=$(kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}' | awk '{split($0,a," "); print a[2]}' | awk '{split($0,a,"."); print a[1]"."a[2]}"."a[3]')
WORKER2_POD_PREFIX=$(kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}' | awk '{split($0,a," "); print a[3]}' | awk '{split($0,a,"."); print a[1]"."a[2]}"."a[3]')

MASTER_KBR_INT_IP=$MASTER_POD_PREFIX".1/24"
WORKER1_KBR_INT_IP=$WORKER1_POD_PREFIX".1/24"
WORKER2_KBR_INT_IP=$WORKER2_POD_PREFIX".1/24"

sudo ip a add $MASTER_KBR_INT_IP dev kbr-int

SET_KBR_INT_IP="sudo ip a add $WORKER1_KBR_INT_IP dev kbr-int"
ssh -i ~/.ssh/worker1 oscar@$WORKER1_MGMT_IP "eval $SET_KBR_INT_IP" 2>&1 > /dev/null

SET_KBR_INT_IP="sudo ip a add $WORKER2_KBR_INT_IP dev kbr-int"
ssh -i ~/.ssh/worker2 oscar@$WORKER2_MGMT_IP "eval $SET_KBR_INT_IP" 2>&1 > /dev/null


SET_ROUTE="sudo ip r add 10.10.0.0/16 dev kbr-int proto static;\
sudo ip r add 10.96.0.0/12 dev kbr-int proto static;\
sudo ip r add 172.10.0.0/16 dev kbr-int proto static"

ssh -i ~/.ssh/worker1 oscar@$WORKER1_MGMT_IP "eval $SET_ROUTE" 2>&1 > /dev/null
ssh -i ~/.ssh/worker2 oscar@$WORKER2_MGMT_IP "eval $SET_ROUTE" 2>&1 > /dev/null
eval $SET_ROUTE
