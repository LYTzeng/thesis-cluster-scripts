kubectl create secret -n kube-system docker-registry gitlab-onos-sona-nightly-docker \
	--docker-server=http://172.30.0.2:5050 \
	--docker-username=oscar \
	--docker-password=5EJmofnHxCGcZiAUwTxU \
	--docker-email=oscar217b@gmail.com

kubectl create secret -n kube-system docker-registry gitlab-sona-cni \
        --docker-server=http://172.30.0.2:5050 \
        --docker-username=oscar \
        --docker-password=2jrYPp2hxoadGH4Hdf8Z \
        --docker-email=oscar217b@gmail.com

kubectl create secret -n kube-system docker-registry gitlab-onos \
        --docker-server=http://172.30.0.2:5050 \
        --docker-username=oscar \
        --docker-password=NodVYxLi4-pEyE6Qsbw7 \
        --docker-email=oscar217b@gmail.com