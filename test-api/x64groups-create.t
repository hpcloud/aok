#!/bin/bash -e

source `dirname $0`/setup.bash


# Create a group and check result
{
  api-post /Groups "$Group_koolkidz"
  is "$(api-status)" 201 \
    'Create group worked'

  is "$(api-output-get '/displayName')" aok.koolkidz \
    'displayName is koolkidz'
}

done_testing

# vim: set sw=2:
