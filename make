#!/bin/sh
RUBYOPT="--yjit" bundle exec rerun -b -- bundle exec rackup --host 0.0.0.0 --port 8080
