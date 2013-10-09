#!/bin/bash -e

plan=6

source test/api/setup.bash $plan

api-get /Users/RESET/
is "$(api-status)" 200 'RESET works'

api-get /Users
is "$(api-output-get '/totalResults')" 0 \
    'Verify no users to start with'

api-post /Users '{"userName":"Ingy","emails":[{"value":"ingy@example.com"}]}'
is "$(api-status)" 200 \
    'Create user worked'
is "$(api-output)" "" \
    'XXX - No JSON output for create User'

api-get /Users
is "$(api-output-get '/totalResults')" 1 \
    'Total users is 1'

guid="$(api-output-get '/resources/0/id')"
api-delete /Users/$guid
# is "$(api-status)" 200 'Delete user works'

api-get /Users
is "$(api-output-get '/totalResults')" 0 \
    'Total users is 0'

