./init.sh 10.10.0.0/16 --skip-phases=addon/kube-proxy && \
./sona-init.sh
kubectl apply -f gitlab_registry_secrets/gitlab-onos-sona-nightly-docker.yaml
kubectl apply -f gitlab_registry_secrets/gitlab-onos.yaml
kubectl apply -f gitlab_registry_secrets/gitlab-sona-cni.yaml
