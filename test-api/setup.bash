# Setup environment for API Tap tests:

INC="$(set -- $PWD/test-api $PWD/ext/*/{bin,lib}; IFS=':'; echo "$*")"
PATH="$INC:$PATH"

AOK_API_URL="http://aok.$VMNAME.local/uaa"
TEST_TAP_BAIL_OUT_ON_ERROR=1

source bpan
bpan:include test/more
source rest-api.bash
source json.bash

source `dirname $0`/users-data.sh

# vim: set sw=2:
