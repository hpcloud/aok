# Setup environment for API Tap tests:

BPANLIB="$(set -- $PWD/test-api $PWD/ext/*/{bin,lib}; IFS=':'; echo "$*")"
PATH="$BPANLIB:$PATH"

AOK_API_URL="http://aok.$VMNAME.local/uaa"

source bpan :std
use Test::More
use REST-API
use JSON

BAIL_ON_FAIL

source `dirname $0`/users-data.sh
source `dirname $0`/groups-data.sh

# TODO - currently conflicts with Test::Tap:END
# trap teardown EXIT
teardown() {
  # Remove tmp files if tests passed
  local rc=$?
  if [ $rc -eq 0 ]; then
    rm -f HEAD STDOUT STDERR
  fi
  return $rc
}
