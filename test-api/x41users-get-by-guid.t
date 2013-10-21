#!/bin/bash -e

source `dirname $0`/setup.bash

# Get a user with filter:
{
  api-get '/Users?filter=username eq "ingy"'
  ingy_guid="$(api-output-get /resources/0/id)"

  api-get /Users/$ingy_guid
  is "$(api-status)" 200 \
    'GET /Users/:id 200'

  is "$(api-output-get '/schemas/0')" urn:scim:schemas:core:1.0 \
    'schemas is correct'
  is "$(api-output-get '/userName')" ingy \
    'userName is ingy'
  is "$(api-output-get '/name/givenName')" Ingy \
    'givenName is Ingy'
  is "$(api-output-get '/name/familyName')" 'döt Net' \
    'familyName is döt Net'
}

done_testing 5
