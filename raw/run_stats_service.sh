#! /bin/bash

cd ~
git clone https://github.com/jace3k/mgr_stats_service.git
cd mgr_stats_service
bundle install
# run when .env file will be filled properly.
# rails s -p 3000 -b 0.0.0.0 &
