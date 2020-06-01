### Stawianie kubernetes potem jak już terraform wykona swój skrypcik postscript.sh:
w skrypciku jest instalacja docker runtime na podstawie:
https://kubernetes.io/docs/setup/production-environment/container-runtimes/

#### Na masterze:
w pierwszym argumencie subnet,
w drugim adres mastera.

kubeadm init --pod-network-cidr=10.244.0.0/16 \
--apiserver-advertise-address 192.168.10.6 \
--apiserver-cert-extra-sans kubernetes.cluster.home



### Potem pokaże sie instrukcja co dalej:

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:



kubeadm join 192.168.10.30:6443 --token mfsc5v.wfvkzdpy0e6yc2ic \
    --discovery-token-ca-cert-hash sha256:a5abfc85e2fe42e86a0b0d37d3c02ea83379f5f44fb3ebab7fb9cc6abd122da1



root@japp-01:~# kubectl get nodes

### POTEM NA NOWYM USERZE:

curl https://rawgit.com/coreos/flannel/master/Documentation/kube-flannel.yml > kube-flannel.yaml
kubectl apply -f kube-flannel.yaml



kubectl get nodes 

powinny byc ready jak wszystkie node'y zostały podłączone tą komendą wyżej.


### Node Roles

kubectl label node node-02 node-role.kubernetes.io/worker=worker

### Dodawanie usera (opcjonalne)

adduser jacek
usermod -aG sudo jacek
su - jacek
sudo whoami ---> powinno dać "root"


### Consolowy dashboard k9s
wget -c https://github.com/derailed/k9s/releases/download/v0.19.1/k9s_Linux_x86_64.tar.gz -O - | tar -xz


### Deploy apki

git clone https://github.com/jace3k/mgr_devops.git
kubectl apply -f mgr_devops/kubernetes/yaml-objects

- trzeba wejśc do każdego serwisu (product i order) do shella i odpalić "rails db:seed"

będzie widoczna na <MASTER_NODE_PUBLIC_IP>:30001

### Lista instancji z adresami ip
openstack server list -c "Name" -c "Networks"



FLOW APKI: git >> docker hub >> kubernetes
- Kazdy serwis ma swój image
- Po pushu na githuba na mastera automatycznie triggerowany jest build:latest
- wszystkie konfiguracje mają swoje repozytorium mgr_devops
- konfiguracja terraforma wymaga stworzenia pary kluczy


############################################################################


DOCKER SWARM

### Stawianie swarm potem jak już terraform wykona swój skrypcik postscript-swarm.sh:


### na masterze:
wg tego iść:
https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/

git clone https://github.com/jace3k/mgr_devops.git
cd mgr_devops/swarm/
docker stack deploy --compose-file docker-compose.yaml mgr
docker node update --availability drain kapp-01
docker service ls


### gdzie jaki serwis chodzi:
docker node ps $(docker node ls -q) --filter desired-state=Running | uniq

potem docker exec it service... i zrobić seed'a




### generowanie pary kluczy
https://docs.oracle.com/cd/E19683-01/806-4078/6jd6cjru7/index.html

 $ ssh-keygen

publiczny - na serwer
prywatny - do logowania






##############################

#### HTTP TESTING:
apt-get install httperf -y

httperf --server 192.168.10.6 --port 30001 --uri /order_stats --num-conns 10 --rate 10

time curl 192.168.10.6:30001/product_stats

grep -E "Connection" results.txt | grep -oE "stddev ([0-9]{0,9}\.[0-9])" | cut -d' ' -f2


#### DB TESTING
curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
sudo apt -y install sysbench
sysbench --version


# Create db and user
psql -U postgres -h order_db_ip -p 30003 -c ''


# INIT DB
sysbench \
--db-driver=pgsql \
--oltp-table-size=100000 \
--oltp-tables-count=24 \
--threads=1 \
--pgsql-host=192.168.10.25 \
--pgsql-port=30003 \
--pgsql-user=sbtest \
--pgsql-password=sbtest \
--pgsql-db=sbtest \
/usr/share/sysbench/tests/include/oltp_legacy/parallel_prepare.lua \
run

# DBTEST

sysbench \
--db-driver=pgsql \
--report-interval=2 \
--oltp-table-size=100000 \
--oltp-tables-count=24 \
--threads=64 \
--time=60 \
--pgsql-host=192.168.10.25 \
--pgsql-port=30003 \
--pgsql-user=sbtest \
--pgsql-password=sbtest \
--pgsql-db=sbtest \
/usr/share/sysbench/tests/include/oltp_legacy/oltp.lua \
run







ANSIBLE:

sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible

hosts:
------
[master]
192.168.10.20

[workers]
192.168.10.16
192.168.10.23
192.168.10.5

[kcluster:children]
master
workers
------


ansible -i hosts all --private-key j-app.pem -m ping

ansible -i hosts master -m shell -a "$(cat kubernetes_init.sh) | bash"
ansible -i hosts master -m shell -a "cat join.txt"

ansible -i hosts workers -m shell -a "kubeadm join 192.168.10.20:6443 --token d6xluk.7msowrbb94b3uqms     --discovery-token-ca-cert-hash sha256:fd48d7ac9943a674fe4c0b338dc9a750bbcfcce4bcb008c2cb0ef0d1c0582499"











#########################################################
#########################################################
#########################################################
#########################################################
Zaczynamy tutaj 
#########################################################
#########################################################
#########################################################
#########################################################


WAŻNE: Na każdym kompie trzeba zainstalować postscript.
-- Kubernetes nodes: /mgr_devops/kubernetes/postscript.sh
-- Swarm nodes: /mgr_devops/swarm/postscript-swarm.sh
-- Native nodes: /mgr_devops/raw/postscript-raw.sh


#########################################################


### Automatyzacja budowania kubernetes na gotowej infrastrukturze:
1. Trzeba wypełnić prawidłowo plik hosts
2. Trzeba mieć private key do wszystkich serwerków


git clone https://github.com/jace3k/mgr_devops.git
export ANSIBLE_HOST_KEY_CHECKING=False
cd mgr_devops
./ansible_install.sh 
nano hosts
touch j-app.pem && chmod 0600 j-app.pem && nano j-app.pem
ansible-playbook playbook.yml -i hosts
ansible-playbook playbook-join-workers.yml -i hosts



### Deployment 

git clone https://github.com/jace3k/mgr_devops.git
kubectl apply -f mgr_devops/kubernetes/yaml_objects/

### Seed

./k9s
s # shell into order_service & product_service
bin/rails c # check if migration succeed
bin/rails db:seed


### Testing
git clone https://github.com/jace3k/mgr_devops.git
cd mgr_devops/
E=k_cloud_ HOST=192.168.10.25 ./benchmark/httperf_stats.sh
E=k_cloud_ HOST=192.168.10.25 ./benchmark/httperf_order.sh
E=k_cloud_ HOST=192.168.10.25 ./benchmark/sysbench_order_db_prepare.sh
E=k_cloud_ HOST=192.168.10.25 ./benchmark/sysbench_order_db_test.sh









### Automatyzacja budowania swarm na gotowej infrastrukturze:
Tak samo jak dla Kubernetes

### Deployment

git clone https://github.com/jace3k/mgr_devops.git
cd mgr_devops/swarm/
docker stack deploy --compose-file docker-compose.yaml mgr
docker node update --availability drain kapp-01
docker service ls

### Seed

gdzie jaki serwis chodzi:
docker node ps $(docker node ls -q) --filter desired-state=Running | uniq

potem docker exec it service... i zrobić seed'a jak w Kubernetes


### Testing
Tak samo jak dla Kubernetes







### NATIVE Deployment

Po instalacji postscript-raw.sh na każdym kompie będzie dostępny postgres.

### Deployment
node-1 - product_svc & product_db
node-2 - order_svc & order_db
node-3 - stats_svc



>>>>>>>>> Product Service & DB
git clone https://github.com/jace3k/mgr_product_service.git
cd mgr_product_service
bundle install

# run when .env file will be filled properly.
echo "DB_NAME=postgres
DB_USER=postgres
DB_PASS=postgres
DB_PORT=5432
DB_HOST=localhost
" | tee .env

rails db:migrate
rails db:seed # run only once
rails s -p 30004 -b 0.0.0.0 -d


>>>>>>>>> Order Service & DB
git clone https://github.com/jace3k/mgr_order_service.git
cd mgr_order_service
bundle install

echo "DB_NAME=postgres
DB_USER=postgres
DB_PASS=postgres
DB_PORT=5432
DB_HOST=localhost
" | tee .env

rails db:migrate
rails db:seed # run only once
rails s -p 30002 -b 0.0.0.0 -d


>>>>>>>>> Stats Service
git clone https://github.com/jace3k/mgr_stats_service.git
cd mgr_stats_service
bundle install

echo "ORDER_HOST=192.168.30.7
ORDER_PORT=30002
PRODUCT_HOST=192.168.30.14
PRODUCT_PORT=30004
" | tee .env

rails s -p 30001 -b 0.0.0.0 -d


TIP: Zatrzymywanie serwera rails
kill -9 $(cat tmp/pids/server.pid)


### Testing
Tak samo jak Kubernetes, tylko trzeba zmieniać hosta odpowiednio dla:
- stats service
- order service
- order db ten sam host co wyżej ale port trzeba dać 5432




