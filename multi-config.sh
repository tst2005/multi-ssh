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
					gettargetsfrom . "$d"
				done
			)
		else
			gettargetsfrom "$GROUP_PATH" "$1"
		fi
	;;
	(list|"")
		if [ "${1:-ALL}" = "ALL" ]; then
			(
				cd -- "$GROUP_PATH" && \
				for d in *; do
					[ -e "$d" ] || continue
					gettargetsfiles "$d"
				done
			) | sed -e 's,\.d/,::,g'
		else
			(cd -- "$GROUP_PATH" && gettargetsfiles "$1") | sed -e 's,\.d/,::,g' || exit 1
		fi
	;;
esac


