#!/bin/bash -e

source `dirname $0`/setup.bash

api-get /Users/RESET/

# Create 13 users:
for a in {a..m}; do
  user=$a$a$a
  api-post /Users '{
    "userName":"'$user'",
    "emails":[{"value":"'$user'@activestate.com"}]
  }'
done

api-get '/Users?count=10'
output="$(api-output-linear)"
got="$(head -n4 <<< "$output")"
want=\
'/totalResults	13
/itemsPerPage	10
/startIndex	1
/schemas/0	"urn:scim:schemas:core:1.0"'
is "$got" "$want" 'header stuff matches'

got="$(tail -n1 <<< "$output")"
is "$got" '/resources/9/emails/0/value	"jjj@activestate.com"' \
  'Got 10 results. 10th user is jjj'

api-get '/Users?startIndex=11&count=10'
got="$(api-output-linear | head -n4)"
output="$(api-output-linear)"
got="$(head -n4 <<< "$output")"
want=\
'/totalResults	13
/itemsPerPage	10
/startIndex	11
/schemas/0	"urn:scim:schemas:core:1.0"'
is "$got" "$want" 'header stuff matches'

got="$(tail -n1 <<< "$output")"
is "$got" '/resources/2/emails/0/value	"mmm@activestate.com"' \
  'Got 3 results. 3rd user is mmm'

done_testing 4
