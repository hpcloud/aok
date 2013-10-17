# Setup environment for API Tap tests:

BPAN_PATH="$(set -- $PWD/test-api $PWD/ext/*/{bin,lib}; IFS=':'; echo "$*")"
PATH="$BPAN_PATH:$PATH"

AOK_API_URL="http://aok.$VMNAME.local/uaa"

source bpan --import include
include test/more
include rest-api
include json

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

# vim: set sw=2:
