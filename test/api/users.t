#!/bin/bash -e

plan=$(ls test/api/response | wc -l)
source test/api/setup.bash $(($plan - 0))

response=$(api-get '/Users')
is "$(echo "$response" | json-to-linear)" \
    "$(< test/api/response/GET-Users-001)" \
    "Verify no users to start with"
