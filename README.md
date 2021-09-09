<h1 align="center">基於 ONOS SONA-CNI 架構之軟體定義網路效能分析與改善</h1>

# 使用說明

本使用說明是 Markdown 格式撰寫，建議用 IDE 開啟預覽，或是到[這裡](https://github.com/LYTzeng/thesis-cluster-scripts)查看，以享有最佳的閱讀體驗。

## 實驗拓樸、界面名稱和 IP

如果沒有要使用實體機器測試效能的話，紙測試架構可行性可使用 [EVE-NG](https://www.eve-ng.net)模擬器建立拓樸。EVE-NG 魔體器的特色在於可以將字型安裝好的虛擬機器移植近來並自訂網路界面及拓樸。
- [eve-ng 使用說明](https://www.eve-ng.net/index.php/documentation/community-cookbook/)

下圖為 EVE-NG 中的拓樸圖，注意網路界面的名稱，在下表有詳細對照。
Ubuntu 中的 Interface name 與 所有ip位址必須和表中相同，因設定檔複雜，我不希望你能找出所有IP做修改，不如將整個架構連帶IP給照抄重建。

![](/img/struct.png)

| hostname | IP           | interface | eve-ng上顯示的界面 | usage                       |
| -------- | ------------ | --------- | ------------------ | --------------------------- |
| master   | 172.30.0.51  | eth0      | e0                 | EVE-NG management interface |
|          | 172.16.0.1   | eth1      | e1                 |                             |
|          | 192.168.60.1 | eth2      | e2                 |                             |
| worker-1 | 172.30.0.52  | eth0      | e0                 | EVE-NG management interface |
|          | 172.16.0.2   | eth1      | e1                 |                             |
|          | 192.168.60.2 | eth2      | e2                 |                             |
| worker-2 | 172.30.0.53  | eth0      | e0                 | EVE-NG management interface |
|          | 172.16.0.3   | eth1      | e1                 |                             |
|          | 192.168.60.3 | eth2      | e2                 |                             |
| ovs      | 172.30.0.54  | eth0      | e0                 | EVE-NG management interface |
|          | L2 br        | eth1      | e1                 | kbr-int                     |
|          | L2 br        | eth2      | e2                 | kbr-int                     |
|          | L2 br        | eth3      | e3                 | kbr-int                     |
|          | L2 br        | eth4      | e4                 | kbr-ns                      |
|          | L2 br        | eth5      | e5                 | kbr-ns                      |
|          | L2 br        | eth6      | e6                 | kbr-ns                      |
|          | bridge       | kbr-int   | -                  |                             |
|          | bridge       | kbr-ns    | -                  |


## 新機器環境架設

本架構要5台PC/Server才能做，如果沒有要測試效能，也可以在虛擬化環境做，只要維持一樣的拓樸即可。一台Master、兩台 worker、一台OvS Access Switch(我原先稱作 external OvS)、以及一台扮演 Client 角色的PC。

如果只運行本論文的架構，OvS Access switch 只需要 4 個網路界面，若連原始的 SONA-CNI 也要拿來測試，則需要至少 7 個網路界面。

請在所有PC/Server安裝 Ubuntu 18.04 Server 版：`ubuntu-18.04.1.0-live-server-amd64.iso` 用這個名稱的 ISO

安裝時請注意 Hostname 的設定，Master 的 Hostname 必須為 `master`，兩個Worker 的Hostname 分別須為 `worker1` 和 `worker2`，其餘則沒有限制。

### switch back to /etc/network/interfaces

安裝完畢後，將 Ubuntu 的 netplan 移除，用回我們熟悉的 ifupdown，因為 netplan 不支援 ovs，netplan 94爛。(扮演Client的那台PC不需要)

步驟：https://askubuntu.com/a/1052023

## 更改界面名稱

網路界面名稱需要特定命名，本專案才能運行，每台K8S節點需要有 `eth0` `eth1` 和 `eth2` 三個界面，執行 `ifconfig` 查看你的界面名稱是否一樣。不一樣則須修改(例如VM常出現`ensXXX`)，請仿照 https://askubuntu.com/a/801310 提到的修改 GRUB 的方式變更設定。

## 架設實驗環境

在Master及Worker Npde上皆執行本專案的 `setup-env.sh`，這是一個很長的腳本，將自動安裝 K8S、OvS、Docker、Kubeadm、python虛擬環境等等

```sh
./setup-env.sh
```

## 套用本實驗之架構

因為要在 master 節點運行腳本來建立K8S cluster，需要把 master 的 SSH public key 加到 worker1, worker2 和 ovs access switch 上面
這樣腳本才不會因為執行 SSH 被問密碼而卡住

在 master 上執行：
```sh
# 建立用來連到 Worker1 和 worker2 的 ssh key
ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/worker1 -q -N ""
ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/worker2 -q -N ""
ssh-copy-id -i $HOME/.ssh/worker1 oscar@<worker1 的 IP>
ssh-copy-id -i $HOME/.ssh/worker2 oscar@<worker2 的 IP>

# 把 Key 加到 OvS Access Switch
ssh-copy-id oscar@<ext-ovs 的 IP>

```

## 啟動 OvS Daemon

在 Master 和 Worker和 OvS Access Switch 上執行
```sh
ovs-ctl start
```

## 建立 K8S 叢集

在Master節點執行本專案`init-sona.sh`腳本
```sh
./init-sona.sh
```

建立完畢後，我的腳本會提示您將一小段指令貼到 worker1 及 worker2 執行

```
Remember to copy kube config to /root/.kube/config on all minion(worker) nodes:

        sudo rm -rf /root/.kube
        sudo mkdir -p /root/.kube
        sudo cp -r /home/oscar/.kube /root
```

## Option 1: 在 K8S Cluster 套用本論文 proposed 架構

### Set Up

在 Master 上執行腳本，會建立 ONOS 和 SONA-CNI 所需的 Pod 和 deployment
```sh
./onos.sh
```

接著不斷地使用 `kgpo` 指令查看Pod狀態，或是 `watch -n1 kubectl get po -o wide` 持續監看Pod狀態。

注意這個時間點：當 `sona-onos-0` 和 `sona-onos-config-0` 都呈現 `1/1 Running` 之時，且三個`sona-node-`開頭的Pod都是`Init:2/3` 的狀態，在worker節點執行 `ovs-vsctl show` 看看是否出現 bridge kbr-int:

```
oscar@master:~/cluster-scripts$ kgpo
NAME                             READY   STATUS              RESTARTS   AGE
coredns-6955765f44-l5trv         0/1     Pending             0          7m29s
coredns-6955765f44-n7h6d         0/1     Pending             0          7m29s
etcd-master                      1/1     Running             0          7m21s
kube-apiserver-master            1/1     Running             0          7m21s
kube-controller-manager-master   1/1     Running             1          7m21s
kube-scheduler-master            1/1     Running             1          7m21s
sona-atomix-0                    1/1     Running             0          2m54s
sona-dummy-27rt8                 0/1     ContainerCreating   0          2m53s
sona-dummy-5rw96                 0/1     ContainerCreating   0          2m53s
sona-dummy-hbpbj                 0/1     ContainerCreating   0          2m53s
sona-node-85hzt                  0/2     Init:2/3            4          2m53s
sona-node-gntnb                  0/2     Init:2/3            0          2m53s
sona-node-n9srz                  0/2     Init:2/3            4          2m53s
sona-onos-0                      1/1     Running             0          2m54s
sona-onos-config-0               1/1     Running             0          2m51s
```

出現 kbr-int 時，**馬上** 執行 `setup-sona-network-intf.sh`

```sh
./setup-sona-network-intf.sh
```

緊接著執行 `init-sona-nodes.sh` 這個腳本：

```sh
./init-sona-nodes.sh
```

### Tear down

如果要移除 SONA-CNI，須重製網路以及砍掉整個 Cluster，執行這兩個腳本可以達成

```sh
./reset-network.sh
./k8s-reset/sh
```

執行完畢後，會重新砍掉並建立一個乾淨的、未安裝CNI的 K8S Cluster，接著就可以選擇在嘗試本論文的架構或是原本的 SONA-CNI

## Option 2: 套用原始(未修改的) SONA-CNI

### Set up

```sh
kubectl apply -f onos-original.yml
```

### Tear down

```sh
./reset-network.sh
./k8s-reset/sh
```

# 程式碼

程式碼分為四個專案：

1. `onos`: 是 ONOS 控制器的原始碼，主要修改了 `apps/k8s-node` 和 `apps/k8s-networking` 這兩個 App，這個專案會被另一個專案 `onos-sona-nightly-docker` pull 下來建立 ONOS Container
2. `onos-sona-nightly-docker`: 主要是透過 `Dockerfile` build ONOS container and then push to Gitlab's container registry
3. `cluster-scripts`: 為了應付極度重複操作的眾多指令，我把他們寫成腳本以利快速執行
4. `sona-cni`: 用 Python 撰寫的 CNI，同時包含在各節點執行的、有設置每個節點網路功能的Init containers，一樣是 build 完推送到 Gitlab container registry

四個專案在此：https://netlab.csie.ntut.edu.tw:8878/explore/projects?tag=%E5%9A%B4%E5%9A%B4%E8%AB%96%E6%96%87

`onos`、`onos-sona-nightly-docker`和`sona-cni`在 Netlab 的 Gitlab 上我都有建立 build container 的 Pipeline，自動建立容器映像檔。

如果要查看 `onos` 專案程式碼在本論文有修改的地方，請使用這個網址在Gitlab查看修改差異：https://netlab.csie.ntut.edu.tw:8878/oscar/onos/-/compare/onos-1.15...onos-1.15-mod?from_project_id=18

如果要查看 `sona-cni` 專案程式碼在本論文有修改的地方，請使用這個網址在Gitlab查看修改差異：https://netlab.csie.ntut.edu.tw:8878/oscar/sona-cni/-/compare/5d39a642128e7067b1f3421ff7fe82dc1a2eee06...mod?from_project_id=15

在 K8S 套用自己 Build 的 Container ，可以使用 Dockerhub 或是自己 Host 的 Container Registry(容器映像倉庫)，本論文使用實驗室架設的 Gitlab 內建的 Container registry

因此你應該不用重新build container ，直接在 `onos.yml` 或是 `onos-original.yml` 裡面定義即可，記得secret 的部份也要設置，我的腳本已經自動幫你作好了：`set-k8s-access-gitlab-registry.sh`，這個在執行`init-sona.sh` 時就已經幫你套用，除非你不使用實驗室裡面的Gitlab，否則無須修改(如果你閱讀此篇的時候，實驗是的Gitlab還健在的話...)。