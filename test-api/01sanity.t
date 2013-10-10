#!/bin/bash -e

source `dirname $0`/setup.bash

# First reset the user db:
{
    api-get /Users/RESET/
    is "$(api-status)" 200 'RESET works'

    api-get /Users
    is "$(api-output-get '/totalResults')" 0 \
        'Verify no users after RESET'
}

# Test adding a user:
{
    api-post /Users "$User_ingy"
    is "$(api-status)" 200 \
        'Create user worked'

    api-get /Users
    is "$(api-output-get '/totalResults')" 1 \
        'Total users is 1'

    is "$(api-output-get '/resources/0/userName')" ingy \
        'userName set correctly'
}

done_testing
