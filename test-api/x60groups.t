#!/bin/bash -e

source `dirname $0`/setup.bash

# Get a group with filter:
{
  api-get '/Groups?filter=displayName eq "aok.admin"'
  is "$(api-output-get '/totalResults')" 1 \
    'Total returned groups is 1'
  is "$(api-output-get '/resources/0/displayName')" aok.admin \
    'Got the correct group'
}

done_testing

# vim: set sw=2:
