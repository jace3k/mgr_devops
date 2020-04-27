#! /bin/bash

cd ~
git clone https://github.com/jace3k/mgr_order_service.git
cd mgr_order_service
bundle install
# run when .env file will be filled properly.
# rails db:migrate
# rails db:seed # run only once
# rails s -p 3000 -b 0.0.0.0 &
