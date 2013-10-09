# Setup environment for API Tap tests:

# Get test resources into path:
PATH="$(dirname "${BASH_SOURCE[0]}"):$(
    IFS=':'; shopt -s nullglob;
    p=(ext/*-bash/{lib,bin}); echo "${p[*]}"
):$PATH"

AOK_API_URL="http://aok.$VMNAME.local/uaa"

source test-simple.bash
source test-more.bash
source rest-api.bash
source json.bash

source `dirname $0`/users-data.sh
