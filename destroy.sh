WORKER1_IP="172.16.0.2"
WORKER2_IP="172.16.0.3"
WORKER1_MGMT_IP="172.30.0.52"
WORKER2_MGMT_IP="172.30.0.53"

KUBEADM_RESET="sudo kubeadm reset -f"
CLEAR_IPTABLES="sudo iptables -F ; sudo iptables -t nat -F ; sudo iptables -t mangle -F ; sudo iptables -X"
FLUSH_ROUTE="sudo ip route flush table main && sudo systemctl restart networking"
RM_KUBECONFIG="rm -rf /home/oscar/.kube && sudo rm -rf /root/.kube"
DEL_BR="sudo ovs-vsctl del-br br-int ; sudo ovs-vsctl del-br br-local; sudo ovs-vsctl del-br kbr-local;sudo ovs-vsctl del-br kbr-ex;sudo ovs-vsctl del-br kbr-int"
DEL_CNI="sudo rm /etc/cni/net.d/1-sona-net.conf"
EXEC_ALL="${KUBEADM_RESET} ; ${CLEAR_IPTABLES} ; ${RM_KUBECONFIG} ; ${DEL_BR} ; ${FLUSH_ROUTE} ; ${DEL_CNI}"

ssh -i ~/.ssh/worker1 oscar@$WORKER1_MGMT_IP "eval $EXEC_ALL"
ssh -i ~/.ssh/worker2 oscar@$WORKER2_MGMT_IP "eval $EXEC_ALL"
eval $EXEC_ALL 
