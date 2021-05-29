GREEN='\033[1;32m'
NC='\033[0m'

CLEAR_IPTABLES="sudo iptables -t nat -F && sudo iptables -F && sudo iptables -X"
eval $CLEAR_IPTABLES


CHANGE_OVSDB_PORT="sudo sed -i '/set ovsdb-server \"$DB_FILE\"/a \        set \"$@\" --remote=ptcp:6650' /usr/share/openvswitch/scripts/ovs-ctl && \
sudo systemctl restart openvswitch-switch"
eval $CHANGE_OVSDB_PORT


sudo rm -rf /root/.kube/config
sudo cp $HOME/.kube/config /root/.kube/config

