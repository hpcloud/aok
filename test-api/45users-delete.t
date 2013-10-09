#!/bin/bash -e

source `dirname $0`/setup.bash

# Deleting a user:
{
    api-get '/Users?filter=username eq "ingy"'
    guid="$(api-output-get '/resources/0/id')"
    api-delete /Users/$guid
    # is "$(api-status)" 200 'XXX - Delete user works'

    api-get /Users
    is "$(api-output-get '/totalResults')" 2 \
        'Total users is 2'

    api-post /users "$User_ingy"
}

done_testing
