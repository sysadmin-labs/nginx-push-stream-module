#!/bin/sh
#
# The version this module reports has to be the version this repository is.
#
# include/ngx_http_push_stream_module_version.h was generated upstream and
# then left behind: it said 0.5.5, and a commit hash belonging to somebody
# else's tree, while the module was 0.6.1.  The statistics handler sends
# both as the X-Nginx-PushStream-Tag and -Commit response headers, so the
# stale pair went out on every request rather than sitting in a file.
#
#     ci/version.sh
#
# CHANGELOG.md is the source of truth, because that is the file a release
# cannot be made without touching.

set -eu

SRC=$(cd "$(dirname "$0")/.." && pwd)

want=$(sed -n 's/^## \([0-9][0-9.]*\)$/\1/p' "$SRC/CHANGELOG.md" | head -1)
[ -n "$want" ] || {
	echo "ci/version.sh: no version heading in CHANGELOG.md" >&2
	exit 1
}

hdr=$SRC/include/ngx_http_push_stream_module_version.h

got=$(sed -n 's/.*NGX_HTTP_PUSH_STREAM_TAG = ngx_string("\(.*\)").*/\1/p' "$hdr")
if [ "$got" != "$want" ]; then
	echo "ci/version.sh: the tag is \"$got\", CHANGELOG.md says \"$want\"" >&2
	exit 1
fi

# Deliberately empty rather than carrying a hash from another tree.  A
# wrong commit is worse than none, and this repository's own hash is not
# known at the time the file is written.
got=$(sed -n 's/.*NGX_HTTP_PUSH_STREAM_COMMIT = ngx_string("\(.*\)").*/\1/p' "$hdr")
if [ -n "$got" ]; then
	echo "ci/version.sh: the commit string is \"$got\", it has to be empty" >&2
	exit 1
fi

echo "ci/version.sh: $want, and the header agrees"
