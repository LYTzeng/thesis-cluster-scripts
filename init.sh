#!/bin/bash

MASTER_IP="172.30.0.51"
WORKER1_IP="172.30.0.52"
WORKER2_IP="172.30.0.54"

RED='\033[0;31m'
GREEN='\033[1;32m'
NC='\033[0m'
YELLOW='\033[1;33m'
print_suc () {
    out=$( echo $1 | awk '{ gsub("-"," ",$1); print $1 }' )
    printf "\r$out ... ${GREEN}[Success]${NC}\n"
}
print_fail () {
    printf "\r$1 ... ${RED}[Fail]${NC}\n"
    echo -e "${RED}$2${NC}"
    return 127
}
suc_or_fail () {
    if [[ $? -eq 0 || -z ${stderr} ]]; then
        print_suc $1
    else
        print_fail $1 $2
    fi
}

if [ $# -lt 1 ]
then
    echo "Syntax: $0 pod-cidr kubeadm-extra-args"
    exit
fi

POD_CIDR=$1
echo -e "${YELLOW}Running kubeadm init${NC}"
extra_args=$(echo ${@:2:$#})
KUBEADM_INIT="sudo kubeadm init --apiserver-advertise-address=$MASTER_IP --pod-network-cidr=$POD_CIDR $extra_args"
stderr=$( $KUBEADM_INIT > /dev/tty)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

KUBEADM_JOIN=$( kubeadm token create --print-join-command )"--apiserver-advertise-address=$MASTER_IP"


echo -n "joining worker1 ..."
stderr=$(ssh -i ~/.ssh/worker1 oscar@$WORKER1_IP "eval "sudo $KUBEADM_JOIN"" 2>&1 > /dev/null)
suc_or_fail "joining-worker1" $stderr

echo -n "joining worker2 ..."
stderr=$(ssh -i ~/.ssh/worker2 oscar@$WORKER2_IP "eval "sudo $KUBEADM_JOIN"" 2>&1 > /dev/null)
suc_or_fail "joining-worker2" $stderr

stderr=$(scp -i ~/.ssh/worker1 $HOME/.kube/config oscar@$WORKER1_IP:/home/oscar/.kube 2>&1 > /dev/null)
suc_or_fail "copying-kubeconfig-to-worker1" $stderr

stderr=$(scp -i ~/.ssh/worker2 $HOME/.kube/config oscar@$WORKER2_IP:/home/oscar/.kube 2>&1 > /dev/null)
suc_or_fail "copying-kubeconfig-to-worker2" $stderr

echo -n "modyfing worker1 kubelet node ip ..."
stderr=$( ssh -i ~/.ssh/worker1 oscar@$WORKER1_IP "sudo sed -i "s/^Environment=KUBELET_EXTRA_ARGS=--node-ip=.*/Environment=KUBELET_EXTRA_ARGS=--node-ip=$WORKER1_IP/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf &&
 sudo systemctl daemon-reload &&
 sudo systemctl restart kubelet" 2>&1 > /dev/null)
suc_or_fail "modifying-worker1-kubelet-env-var" $stderr

echo -n "modyfing worker2 kubelet node ip ..."
stderr=$( ssh -i ~/.ssh/worker2 oscar@$WORKER2_IP "sudo sed -i "s/^Environment=KUBELET_EXTRA_ARGS=--node-ip=.*/Environment=KUBELET_EXTRA_ARGS=--node-ip=$WORKER2_IP/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf &&
 sudo systemctl daemon-reload &&
 sudo systemctl restart kubelet" 2>&1 > /dev/null)
suc_or_fail "modifying-worker2-kubelet-env-var" $stderr

echo -n "modyfing master kubelet node ip ..."
stderr=$(sudo sed -i "s/^Environment=KUBELET_EXTRA_ARGS=--node-ip=.*/Environment=KUBELET_EXTRA_ARGS=--node-ip=$MASTER_IP/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf && sudo systemctl daemon-reload && sudo systemctl restart kubelet)
suc_or_fail "modifying-master-kubelet-env-var" $stderr

