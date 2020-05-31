PGPASSWORD=postgres dropdb -U postgres -h ${HOST} -p 30003 sbtest
PGPASSWORD=postgres createdb -U postgres -h ${HOST} -p 30003 sbtest
echo "done."
