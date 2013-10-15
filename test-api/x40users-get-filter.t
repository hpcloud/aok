#!/bin/bash -e

source `dirname $0`/setup.bash

# Get a user with filter:
{
  api-get '/Users?filter=username eq "ingy"'
  is "$(api-output-get '/totalResults')" 1 \
    'Total returned users is 1'
  is "$(api-output-get '/resources/0/userName')" ingy \
    'Got the correct user'
}

done_testing

# vim: set sw=2:
