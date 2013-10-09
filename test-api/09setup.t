#!/bin/bash

source `dirname $0`/setup.bash

source `dirname $0`/users-populate.sh

is "$(api-output-get '/totalResults')" 3 \
    'Total returned users is 3'

done_testing
