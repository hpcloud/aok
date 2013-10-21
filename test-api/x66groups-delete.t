#!/bin/bash -e

source `dirname $0`/setup.bash

# Deleting a group:
{
  api-get '/Groups?filter=displayName eq "aok.koolkidz"'
  guid="$(api-output-get '/resources/0/id')"
  api-delete "/Groups/$guid"
  is "$(api-status)" 200 'Delete group works'

  api-get /Groups
  is "$(api-output-get '/totalResults')" 2 \
    'Total groups is 2'
}

done_testing 2
