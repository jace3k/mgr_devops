sudo apt-get install httperf -y

# run as follows:
#
# HOST=192.168.10.25 ./httperf_stats.sh

STARTED_AT=$(date +%Y_%m_%d_%H_%M_%S)
echo "Started at: ${STARTED_AT}"

perform () {
  echo "${1}..."
  httperf --server ${HOST} --port 30001 --uri /order_stats --num-conns ${1} --rate ${1} | tee -a ${E}stats_svc_results_${STARTED_AT}.txt
}

perform 10
perform 20
perform 50
perform 100
perform 120
perform 150
perform 180
perform 200
perform 210
perform 220
perform 250
perform 280
perform 300

echo "done"

