PORT=30003
STARTED_AT=$(date +%Y_%m_%d_%H_%M_%S)
echo "Started at: ${STARTED_AT}"


rw_test () {
echo "-------------------\n-----------------" | tee -a ${E}order_db_result_${STARTED_AT}.txt
echo "READ/WRITE TESTING (table size: ${1})" | tee -a ${E}order_db_result_${STARTED_AT}.txt
echo "-------------------\n-----------------" | tee -a ${E}order_db_result_${STARTED_AT}.txt


sysbench \
--db-driver=pgsql \
--report-interval=2 \
--oltp-table-size=${1} \
--oltp-tables-count=24 \
--threads=64 \
--time=60 \
--pgsql-host=${HOST} \
--pgsql-port=${PORT} \
--pgsql-user=sbtest \
--pgsql-password=sbtest \
--pgsql-db=sbtest \
/usr/share/sysbench/tests/include/oltp_legacy/oltp.lua \
run | tee -a results/${E}order_db_result_${STARTED_AT}.txt
}


ro_test () {
echo "-------------------\n-----------------" | tee -a ${E}order_db_result_${STARTED_AT}.txt
echo "READ ONLY TESTING (table size: ${1})" | tee -a ${E}order_db_result_${STARTED_AT}.txt
echo "-------------------\n-----------------" | tee -a ${E}order_db_result_${STARTED_AT}.txt

sysbench \
--db-driver=pgsql \
--report-interval=2 \
--oltp-table-size=${1} \
--oltp-tables-count=24 \
--threads=64 \
--time=60 \
--pgsql-host=${HOST} \
--pgsql-port=${PORT} \
--pgsql-user=sbtest \
--pgsql-password=sbtest \
--pgsql-db=sbtest \
/usr/share/sysbench/tests/include/oltp_legacy/select.lua \
run | tee -a results/${E}order_db_result_${STARTED_AT}.txt
}


rw_test 100
rw_test 1000
rw_test 10000
rw_test 100000
rw_test 1000000

ro_test 100
ro_test 1000
ro_test 10000
ro_test 100000
ro_test 1000000

