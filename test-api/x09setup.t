#!/bin/bash -e

source `dirname $0`/setup.bash


source `dirname $0`/users-populate.sh

is "$(api-output-get '/totalResults')" 3 \
  'Total returned users is 3'

source `dirname $0`/groups-populate.sh

is "$(api-output-get '/totalResults')" 2 \
  'Total returned groups is 2'


done_testing
# vim: set sw=2:
