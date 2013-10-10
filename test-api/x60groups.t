#!/bin/bash -e

echo '1..0 # SKIP Groups not ready to test.'
exit 0

plan=1
source test/api/setup.bash $plan

