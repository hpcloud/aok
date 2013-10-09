# Setup environment for API Tap tests:

# Get test resources into path:
PATH="$(dirname "${BASH_SOURCE[0]}"):$(
    IFS=':'; shopt -s nullglob;
    p=(ext/*-bash/{lib,bin}); echo "${p[*]}"
):$PATH"

AOK_API_URL="http://aok.$VMNAME.local/uaa"

source test-simple.bash tests $1
source test-more.bash
source rest-api.bash
source json.bash
