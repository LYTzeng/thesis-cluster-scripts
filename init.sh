#!/bin/bash

MASTER_IP="172.30.0.54"

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

echo -n "modyfing master kubelet node ip ..."
stderr=$(sudo sed -i "s/^Environment=KUBELET_EXTRA_ARGS=--node-ip=.*/Environment=KUBELET_EXTRA_ARGS=--node-ip=$MASTER_IP/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf && sudo systemctl daemon-reload && sudo systemctl restart kubelet)
suc_or_fail "modifying-master-kubelet-env-var" $stderr

kubectl taint nodes worker-2 node-role.kubernetes.io/master-
