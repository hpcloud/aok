#!/bin/bash -e

PATH="$(dirname "${BASH_SOURCE[0]}"):$(IFS=:; shopt -s nullglob; p=(ext/*-bash/{lib,bin}); echo "${p[*]}"):$PATH"
AOK_API_URL="http://aok.$VMNAME.local/uaa"

plan=$(ls test/api/response | wc -l)
source test-simple.bash tests $plan
source test-more.bash
source rest-api.bash
source json.bash

is "$(api-get '/Users' | json-to-linear)" \
    "$(< test/api/response/GET-Users)" \
    '/Users'
