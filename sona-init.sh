GREEN='\033[1;32m'
NC='\033[0m'

WORKER1_IP="172.16.0.2"
WORKER2_IP="172.16.0.3"
MASTER_IP="172.16.0.1"

CLEAR_IPTABLES="sudo iptables -t nat -F && sudo iptables -F && sudo iptables -X"
eval $CLEAR_IPTABLES
ssh -i ~/.ssh/worker1 oscar@$WORKER1_IP "eval $CLEAR_IPTABLES"
ssh -i ~/.ssh/worker2 oscar@$WORKER2_IP "eval $CLEAR_IPTABLES"

# CHANGE_OVSDB_PORT="sudo sed -i \'/set ovsdb-server \"\$DB_FILE\"/a \\        set \\\"\$\@\\\" --remote=ptcp:6650\' /usr/local/share/openvswitch/scripts/ovs-ctl && \
# sudo /usr/local/share/openvswitch/scripts/ovs-ctl restart"
# eval $CHANGE_OVSDB_PORT
# ssh -i ~/.ssh/worker1 oscar@$WORKER1_IP "eval $CHANGE_OVSDB_PORT"
# ssh -i ~/.ssh/worker2 oscar@$WORKER2_IP "eval $CHANGE_OVSDB_PORT"

sudo rm -rf /root/.kube/config
sudo mkdir -p /root/.kube
sudo cp $HOME/.kube/config /root/.kube/config
printf "\nRemember to copy kube config to /root/.kube/config on all minion(worker) nodes:\n\n"
printf "${GREEN}\tsudo rm -rf /root/.kube
\tsudo mkdir -p /root/.kube
\tsudo cp -r $HOME/.kube /root${NC}\n\n"
