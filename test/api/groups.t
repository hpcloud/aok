#!/bin/bash -e

plan=$(ls test/api/response | wc -l)
source test/api/setup.bash $plan

response=$(api-get '/Groups')
is "$(echo "$response" | json-to-linear)" \
    "$(< test/api/response/GET-Groups)" \
    '/Users'
