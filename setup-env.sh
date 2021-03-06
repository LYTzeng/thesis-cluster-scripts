#!/bin/bash
#############################
### Install Docker
#############################

# Variables
DOCKER_VERSION='5:19.03.15~3-0~ubuntu-bionic'
GITLAB_CONTAINER_REGISTRY='172.30.0.2:5050'

# Install using the repository
sudo apt-get update -q
sudo apt-get install -yq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
    "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update -q
# Install the latest version of Docker Engine - Community and containerd
sudo apt-get install -yq docker-ce=$DOCKER_VERSION docker-ce-cli=$DOCKER_VERSION
sudo apt-mark hold docker-ce docker-ce-cli
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
# If you want to use docker without sudo, run the command below then exit and login again.
sudo usermod -aG docker $USER

sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "insecure-registries" : ["$GITLAB_CONTAINER_REGISTRY"]
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker

#############################
### Install Kubernetes and Kubeadm
#############################

# Variables
K8S_VER='1.17.17-00'

sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
sudo apt-get install -yq apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update -q
sudo apt-get install -yq kubelet=$K8S_VER kubeadm=$K8S_VER kubectl=$K8S_VER
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet

#############################
### Install OvS
#############################

OVS_VERSION='2.10.7'

curl -OL https://www.openvswitch.org/releases/openvswitch-${OVS_VERSION}.tar.gz
tar xvzf openvswitch-${OVS_VERSION}.tar.gz
cd openvswitch-${OVS_VERSION}
sudo apt-get install -yq build-essential \
    fakeroot graphviz autoconf automake bzip2 debhelper dh-autoreconf libssl-dev \
    libtool openssl procps python-all python-qt4 python-twisted-conch python-zopeinterface \
    module-assistant dkms make libc6-dev python-argparse uuid-runtime netbase kmod \
    python-twisted-web iproute2 ipsec-tools racoon

./boot.sh
./configure --with-linux=/lib/modules/$(uname -r)/build
make
sudo make install
sudo make modules_install
config_file="/etc/depmod.d/openvswitch.conf"
for module in datapath/linux/*.ko; do
  modname="$(basename ${module})"
  echo "override ${modname%.ko} * extra" | sudo tee -a "$config_file"
  echo "override ${modname%.ko} * weak-updates" | sudo tee -a  "$config_file"
  done
sudo depmod -a
sudo /sbin/modprobe openvswitch
/sbin/lsmod | grep openvswitch
echo -e '\nPATH=/usr/local/share/openvswitch/scripts:$PATH' | tee -a /home/`whoami`/.bashrc
echo -e '\nPATH=/usr/local/share/openvswitch/scripts:$PATH' | sudo tee -a /root/.bashrc
sudo /usr/local/share/openvswitch/scripts/ovs-ctl start
cd ..
rm openvswitch-${OVS_VERSION}.tar.gz
rm -rf openvswitch-${OVS_VERSION}

#############################
### Useful Aliases
#############################
cat >> /home/`whoami`/.bashrc << 'EOF'

# useful aliases
alias ovs-ctl='sudo env PATH=$PATH ovs-ctl'
alias ovs-vsctl='sudo ovs-vsctl'
alias ovs-ofctl='sudo ovs-ofctl -O OpenFlow14'
alias ovs-appctl='sudo ovs-appctl'

alias k='kubectl'
alias kg='kubectl get'
alias kgpo='kubectl get pod'
alias ka='kubectl apply -f'
alias krm='kubectl delete'
alias krmf='kubectl delete -f'
alias kgsvc='kubectl get service'
alias kgw='kubectl get --watch'
alias kgpow='kubectl get pods --watch'
alias kgpoowide='kubectl get pods -o=wide'
alias kgowide='kubectl get -o=wide'
EOF

#############################
### Install pyenv and dependencies for ovs-tcpdump
#############################

source <(curl -L https://gist.githubusercontent.com/LYTzeng/b5d8c178bce3f35813dda06b8127a9c8/raw/12ed640dd7a9a7f1b55d9991c7236fdacdd041c6/install-pyenv-ubuntu.sh)
cat >> /home/`whoami`/.bashrc << 'EOF'

# pyenv settings
PATH=$PATH:/home/$USER/.pyenv/bin
eval "$(pyenv init --path)"
EOF
source /home/`whoami`/.bashrc
/home/$USER/.pyenv/bin/pyenv install 3.6.9
/home/$USER/.pyenv/bin/pyenv global 3.6.9
pip install ovs netifaces
standalong_py3=( ovs-tcpdump ovs-pcap )
for file in "${standalong_py3[@]}"
do
  env_python_path="#\!/home/$(whoami)/.pyenv/versions/3.6.9/bin/python"
  sudo sed -i "1s@.*@$env_python_path@" /usr/local/bin/$file
done

#############################
### Install kubens cli tool
#############################
KUBENS_URL='https://github.com/ahmetb/kubectx/releases/download/v0.9.3/kubens_v0.9.3_linux_x86_64.tar.gz'
cd ~
curl -sL $KUBENS_URL| tar xz
sudo mv kubens /usr/local/bin
rm LICENSE
