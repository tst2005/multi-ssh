#!/bin/sh

set -e

. ./lib/target.lib.sh

GROUP_PATH="./groups"

case "$2" in
	(cat|dump)
		if [ "$1" = "ALL" ]; then
			(
				cd -- "$GROUP_PATH" && \
				for x in *; do
					case "$x" in
						(*'.list') [ -f "$x" ] || continue ;;
						(*) [ -d "$x" ] || continue ;;
					esac
					target_files . "$x" || true
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
				for x in *; do
					case "$x" in
						(*'.list') [ -f "$x" ] || continue ;;
						(*) [ -d "$x" ] || continue ;;
					esac
					target_files "$x"
				done
			) | target_long2short
		else
			(cd -- "$GROUP_PATH" && target_files "$1") | target_long2short || exit 1
		fi
	;;
esac


