GREEN='\033[1;32m'
NC='\033[0m'

WORKER1_IP="172.30.0.52"
WORKER2_IP="172.30.0.54"
MASTER_IP="172.30.0.51"

CLEAR_IPTABLES="sudo iptables -t nat -F && sudo iptables -F && sudo iptables -X"
eval $CLEAR_IPTABLES
ssh -i ~/.ssh/worker1 oscar@$WORKER1_IP "eval $CLEAR_IPTABLES"
ssh -i ~/.ssh/worker2 oscar@$WORKER2_IP "eval $CLEAR_IPTABLES"

CHANGE_OVSDB_PORT="sudo sed -i '/set ovsdb-server \"$DB_FILE\"/a \        set \"$@\" --remote=ptcp:6650' /usr/share/openvswitch/scripts/ovs-ctl && \
sudo systemctl restart openvswitch-switch"
eval $CHANGE_OVSDB_PORT
ssh -i ~/.ssh/worker1 oscar@$WORKER1_IP "eval $CHANGE_OVSDB_PORT"
ssh -i ~/.ssh/worker2 oscar@$WORKER2_IP "eval $CHANGE_OVSDB_PORT"

sudo rm -rf /root/.kube/config
sudo cp $HOME/.kube/config /root/.kube/config
printf "\nRemember to copy kube config to /root/.kube/config on all minion(worker) nodes:\n\n"
printf "${GREEN}\tsudo rm -rf /root/.kube/config
\tsudo cp $HOME/.kube/config /root/.kube/config${NC}\n\n"
