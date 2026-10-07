#!/bin/sh
# KernelSU-Next is a submodule pinned to an upstream release; this tree carries
# the changes it needs on Linux 4.4 as patches. Apply them unless they already
# are. Called from drivers/Makefile; prints "ok" on success.

cd "$(dirname "$0")/.." || exit 1
ksu=KernelSU-Next

patches=$(ls KernelSU-Next-patches/*.patch 2>/dev/null)
[ -n "$patches" ] || { echo ok; exit 0; }

# Build the release with the patches applied in a scratch index, to compare
# the submodule's files against.
index=$(mktemp)
trap 'rm -f "$index"' EXIT
GIT_INDEX_FILE=$index git -C $ksu read-tree HEAD || exit 1
for patch in $patches; do
	GIT_INDEX_FILE=$index git -C $ksu apply --cached "../$patch" || {
		echo "$patch does not apply to the KernelSU-Next release" >&2
		exit 1
	}
done

if GIT_INDEX_FILE=$index git -C $ksu diff --quiet; then
	:  # already patched
elif git -C $ksu diff --quiet HEAD; then
	for patch in $patches; do
		git -C $ksu apply "../$patch" >&2 || exit 1
	done
else
	echo "KernelSU-Next has changes other than KernelSU-Next-patches" >&2
	exit 1
fi
echo ok
