# Setup environment for API Tap tests:

BPAN_PATH="$(set -- $PWD/test-api $PWD/ext/*/{bin,lib}; IFS=':'; echo "$*")"
PATH="$BPAN_PATH:$PATH"

AOK_API_URL="http://aok.$VMNAME.local/uaa"
TEST_TAP_FAIL_FAST=1

source bpan --import include
include test/more
include rest-api
include json

source `dirname $0`/users-data.sh
source `dirname $0`/groups-data.sh

trap teardown EXIT
teardown() {
  # Remove tmp files if tests passed
  local rc=$?
  if [ $rc -eq 0 ]; then
    rm -f HEAD STDOUT STDERR
  fi
  return $rc
}

# vim: set sw=2:
