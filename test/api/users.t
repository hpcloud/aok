#!/bin/bash -e

# ToDo:
# - move ./test/api/ ./test-api/
# - split up into smaller tests
# - Support done-testing
# - escape query strings
# - get correct git repos in Makefile. use a version file.

plan=9

source test/api/setup.bash $plan

# Stock user info:
{
    User_ingy='{
        "userName":"ingy",
        "emails":[{"value":"ingy@activestate.com"}]
    }'
    User_aocole='{
        "userName":"aocole",
        "emails":[{"value":"aocole@activestate.com"}]
    }'
    User_ziggy='{
        "userName":"ziggy",
        "emails":[{"value":"ziggy@activestate.com"}]
    }'
}

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
    is "$(api-output)" "" \
        'XXX - No JSON output for create User'
    # TODO test for correct JSON fields

    api-get /Users
    is "$(api-output-get '/totalResults')" 1 \
        'Total users is 1'

    is "$(api-output-get '/resources/0/userName')" ingy \
        'userName set correctly'
}

# Make generic user db:
{
    api-get /Users/RESET/
    api-post /Users "$User_ingy"
    api-post /Users "$User_aocole"
    api-post /Users "$User_ziggy"
    api-get /Users
}

# Get a user with filter:
{
    api-get '/Users?filter=username eq "ingy"'
    is "$(api-output-get '/totalResults')" 1 \
        'Total returned users is 1'
    is "$(api-output-get '/resources/0/userName')" ingy \
        'Got the correct user'
}

# Deleting a user:
{
    # Get guid from 'ingy' above.
    guid="$(api-output-get '/resources/0/id')"
    api-delete /Users/$guid
    # is "$(api-status)" 200 'XXX - Delete user works'

    api-get /Users
    is "$(api-output-get '/totalResults')" 2 \
        'Total users is 2'

    api-post /users "$User_ingy"
}
