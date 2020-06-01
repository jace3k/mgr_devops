sudo apt-get install httperf -y

# run as follows:
# E=k_ - kubernetes
# E=s_ - swarm
#
# E=k_ HOST=192.168.10.25 ./httperf_order.sh

STARTED_AT=$(date +%Y_%m_%d_%H_%M_%S)
echo "Started at: ${STARTED_AT}"

perform () {
  echo "${1}..."
  httperf --server ${HOST} --port 30002 --uri /orders --num-conns ${1} --rate ${1} | tee -a ${E}order_svc_results_${STARTED_AT}.txt
}

perform 10
perform 20
perform 50
perform 100
perform 120
perform 150
perform 180
perform 200
perform 300
perform 400
perform 500
perform 600
perform 800
perform 1000
echo "done"

