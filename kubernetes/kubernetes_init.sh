IP=$(ifconfig | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -n 1)
echo $IP

kubeadm init --pod-network-cidr=10.244.0.0/16 \
--apiserver-advertise-address $IP \
--apiserver-cert-extra-sans kubernetes.cluster.home

echo "Creating .kube and copying config"
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

echo "Adding Flannel"
curl https://rawgit.com/coreos/flannel/master/Documentation/kube-flannel.yml > kube-flannel.yaml
kubectl apply -f kube-flannel.yaml

echo "Adding dashboard"
wget -c https://github.com/derailed/k9s/releases/download/v0.19.1/k9s_Linux_x86_64.tar.gz -O - | tar -xz

