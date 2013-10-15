#!/bin/bash -e

source `dirname $0`/setup.bash

# Get a group with filter:
{
  api-get '/Groups?filter=displayname eq "aok.admin"'
  admin_guid="$(api-output-get /resources/0/id)"

  api-get /Groups/$admin_guid
  is "$(api-status)" 200 \
    'GET /Groups/:id 200'

  is "$(api-output-get '/displayName')" aok.admin \
    'displayName is aok.admin'
}

done_testing

# vim: set sw=2:
