#!/bin/sh

set -e

. ./lib/target.lib.sh

GROUP_PATH="./groups"

case "$2" in
	(cat|dump)
		if [ "$1" = "ALL" ]; then
			(
				cd -- "$GROUP_PATH" && \
				for d in *; do
					[ -e "$d" ] || continue
					target_files . "$d"
				done
			)
		else
			target_getfrom "$GROUP_PATH" "$1"
		fi
	;;
	(list|"")
		if [ "${1:-ALL}" = "ALL" ]; then
			(
				cd -- "$GROUP_PATH" && \
				for d in *; do
					[ -e "$d" ] || continue
					target_files "$d"
				done
			) | target_long2short
		else
			(cd -- "$GROUP_PATH" && target_files "$1") | target_long2short || exit 1
		fi
	;;
esac


