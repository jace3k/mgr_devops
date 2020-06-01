PORT=30003
# install psql client
sudo apt-get install -y postgresql-client

# install sysbench
curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
sudo apt -y install sysbench
sysbench --version

PGPASSWORD=postgres psql -U postgres -h ${HOST} -p ${PORT} -c "CREATE USER sbtest WITH PASSWORD 'sbtest';"
PGPASSWORD=postgres psql -U postgres -h ${HOST} -p ${PORT} -c "CREATE DATABASE sbtest;"
PGPASSWORD=postgres psql -U postgres -h ${HOST} -p ${PORT} -c "GRANT ALL PRIVILEGES ON DATABASE sbtest TO sbtest;"

sysbench \
--db-driver=pgsql \
--oltp-table-size=100000 \
--oltp-tables-count=24 \
--threads=1 \
--pgsql-host=${HOST} \
--pgsql-port=${PORT} \
--pgsql-user=sbtest \
--pgsql-password=sbtest \
--pgsql-db=sbtest \
/usr/share/sysbench/tests/include/oltp_legacy/parallel_prepare.lua \
run
