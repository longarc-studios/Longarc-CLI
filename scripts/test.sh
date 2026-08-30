#!/bin/sh

set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

/bin/sh -n "$root/install.sh"
/bin/sh -n "$root/uninstall.sh"
/bin/sh -n "$root/tests/public-boundary.test.sh"
/bin/sh "$root/tests/public-boundary.test.sh"
