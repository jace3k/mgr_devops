#! /bin/bash

echo "Postscript started!" >> /root/output.txt

command curl -sSL https://rvm.io/mpapis.asc | gpg --import - >> /root/output.txt
command curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - >> /root/output.txt
curl -sSL https://get.rvm.io | bash -s stable --rails >> /root/output.txt
source /usr/local/rvm/scripts/rvm >> /root/output.txt
rvm --default install ruby-2.6.3 >> /root/output.txt
rvm -v >> /root/output.txt
ruby -v >> /root/output.txt

apt-get update -y >> /root/output.txt
sudo apt-get install -y libpq-dev nano >> /root/output.txt

gem install bundler >> /root/output.txt
gem install pg -v '1.2.2' >> /root/output.txt

# POSTGRESQL
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RELEASE=$(lsb_release -cs)
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update >> /root/output.txt
sudo apt -y install postgresql-11 >> /root/output.txt
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/11/main/postgresql.conf
sudo systemctl restart postgresql >> /root/output.txt
sudo -u postgres psql -c "alter user postgres with password 'postgres';" >> /root/output.txt

echo "Postscript done." >> /root/output.txt
