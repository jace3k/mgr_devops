sudo apt-get install httperf -y

# run as follows:
#
# E=k_cloud HOST=192.168.10.25 ./httperf_stats.sh

STARTED_AT=$(date +%Y_%m_%d_%H_%M_%S)
echo "Started at: ${STARTED_AT}"

perform () {
  echo "${1}..."
  httperf --server ${HOST} --port 30001 --uri /order_stats --num-conns ${1} --rate ${1} | tee -a results/${E}stats_svc_results_${STARTED_AT}.txt
}

perform 10
perform 20
perform 50
perform 100
perform 150
perform 200
perform 250
perform 300
perform 350
perform 400
perform 450
perform 500
perform 600
perform 700
perform 800
perform 900
perform 1000
echo "done"
