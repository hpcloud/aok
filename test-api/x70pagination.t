#!/bin/bash -e

source `dirname $0`/setup.bash

api-get /Users/RESET/

for a in {a..m}; do
  user=$a$a$a
  api-post /Users '{
    "userName":"'$user'",
    "emails":[{"value":"'$user'@activestate.com"}]
  }'
done

api-get /Users
got1="$(api-output-linear | head -n4)"
want1=\
'/totalResults	13
/itemsPerPage	10
/startIndex	1
/schemas/0	"urn:scim:schemas:core:1.0"'
is "$got1" "$want1" 'header stuff matches'

done_testing 1

# vim: set sw=2 ft=sh:
