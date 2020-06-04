#! /bin/bash

echo "Postscript started!" | tee -a /root/output.txt

command curl -sSL https://rvm.io/mpapis.asc | gpg --import -
command curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable --rails | tee -a /root/output.txt
source /usr/local/rvm/scripts/rvm | tee -a /root/output.txt
rvm --default install ruby-2.6.3 | tee -a /root/output.txt
rvm -v | tee -a /root/output.txt
ruby -v | tee -a /root/output.txt

apt-get update -y | tee -a /root/output.txt
sudo apt-get install -y libpq-dev nano | tee -a /root/output.txt

gem install bundler | tee -a /root/output.txt
gem install pg -v '1.2.2' | tee -a /root/output.txt

# POSTGRESQL
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RELEASE=$(lsb_release -cs)
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update | tee -a /root/output.txt
sudo apt -y install postgresql-11 | tee -a /root/output.txt
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/11/main/postgresql.conf
sed -i '1ihost  all  all 0.0.0.0/0 md5' /etc/postgresql/11/main/pg_hba.conf
sudo systemctl restart postgresql | tee -a /root/output.txt
sudo -u postgres psql -c "alter user postgres with encrypted password 'postgres';" | tee -a /root/output.txt

echo "Postscript done." | tee -a /root/output.txt
