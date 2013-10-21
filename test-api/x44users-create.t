#!/bin/bash -e

source `dirname $0`/setup.bash

# Create a user and check result
{
  api-post /Users "$User_ted"
  is "$(api-status)" 201 \
    'Create user worked'

  is "$(api-output-get '/schemas/0')" urn:scim:schemas:core:1.0 \
    'schemas is correct'
  is "$(api-output-get '/userName')" ted \
    'userName is ted'
  is "$(api-output-get '/name/givenName')" Theodore \
    'givenName is Theodore'
  is "$(api-output-get '/name/familyName')" "Marshall" \
    'familyName is Marshall'
}

done_testing 5
