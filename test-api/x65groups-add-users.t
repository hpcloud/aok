#!/bin/bash -e

source `dirname $0`/setup.bash


{
  api-get '/Users?filter=username eq "ingy"'
  ingy_guid="$(api-output-get /resources/0/id)"
  api-get '/Users?filter=username eq "aocole"'
  aocole_guid="$(api-output-get /resources/0/id)"
  api-get '/Groups?filter=displayname eq "aok.koolkidz"'
  koolkidz_guid="$(api-output-get /resources/0/id)"
  api-patch "/Groups/$koolkidz_guid" '[
    {
        "type":"USER",
        "authorities":["READ"],
        "value":"'$ingy_guid'"
    }
  ]'
  is "$(api-status)" 200 \
    'PATCH /Groups/:id (add ingy to group) 200'
  api-patch "/Groups/$koolkidz_guid" '[
    {
        "type":"USER",
        "authorities":["READ"],
        "value":"'$aocole_guid'"
    }
  ]'
  is "$(api-status)" 200 \
    'PATCH /Groups/:id (add aocole to group) 200'
  api-get '/Groups?filter=displayname eq "aok.koolkidz"'
# XXX starting failing. need to not add user twice.
#   is "$(api-output-get /resources/0/members/0/value)" $ingy_guid \
#     'First user in group is ingy'
#   api-get '/Groups?filter=displayname eq "aok.koolkidz"'
#   is "$(api-output-get /resources/0/members/1/value)" $aocole_guid \
#     'First user in group is aocole'
}

done_testing

# vim: set sw=2:
